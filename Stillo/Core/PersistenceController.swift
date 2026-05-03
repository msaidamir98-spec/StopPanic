import CloudKit
import CoreData
import os.log

// MARK: - PersistenceController

/// Core Data + CloudKit контроллер.
/// При первом запуске автоматически мигрирует данные из JSON-файлов.
@MainActor
final class PersistenceController {
    // MARK: Lifecycle

    private init() {
        // Check at runtime whether the iCloud entitlement is present.
        // NSPersistentCloudKitContainer crashes immediately without it,
        // so we fall back to a plain NSPersistentContainer for local-only builds.
        let hasCloudEntitlement = Self.iCloudEntitlementAvailable()

        if hasCloudEntitlement {
            container = NSPersistentCloudKitContainer(name: "Stillo")
        } else {
            Self.log.info("iCloud entitlement not found — using local-only Core Data")
            container = NSPersistentContainer(name: "Stillo")
        }

        // Store description
        guard let description = container.persistentStoreDescriptions.first else {
            Self.log.fault("No persistent store descriptions — falling back to in-memory store")
            let fallback = NSPersistentStoreDescription()
            fallback.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [fallback]
            container.loadPersistentStores { _, error in
                if let error { Self.log.error("In-memory store failed: \(error.localizedDescription)") }
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
            return
        }

        if hasCloudEntitlement {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.MSK-PRODUKT.StopPanic"
            )
        }

        // History tracking (needed for CloudKit sync, harmless without it)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { [weak self] _, error in
            if let error {
                Self.log.error("Core Data failed to load: \(error.localizedDescription)")
                Task { @MainActor in self?.storeLoadFailed = true }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        if hasCloudEntitlement {
            NotificationCenter.default.addObserver(
                forName: .NSPersistentStoreRemoteChange,
                object: container.persistentStoreCoordinator,
                queue: .main
            ) { [log = Self.log] _ in
                log.info("Received remote CloudKit change")
            }
        }
    }

    // MARK: Internal

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    /// Флаг: загрузка хранилища не удалась
    private(set) var storeLoadFailed = false

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Безопасное сохранение с возвратом успешности
    @discardableResult
    func save() -> Bool {
        guard !storeLoadFailed else {
            Self.log.warning("Skipping save — store not loaded")
            return false
        }
        let ctx = viewContext
        guard ctx.hasChanges else { return true }
        do {
            try ctx.save()
            return true
        } catch {
            Self.log.error("Core Data save failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Privacy / Wipe

    /// Удаляет ВСЕ пользовательские данные из Core Data + UserDefaults.
    /// Apple Guideline 5.1.1 (iv) + GDPR Right to Erasure.
    /// 2026-05-03: добавлено в рамках Master Plan День 2.
    ///
    /// - Note: вызывается из PrivacySettingsView с двойным подтверждением.
    ///   Возвращает количество удалённых entities, либо -1 при ошибке.
    @discardableResult
    func wipeAllData() -> Int {
        guard !storeLoadFailed else {
            Self.log.error("Wipe failed — store not loaded")
            return -1
        }

        // 1. Удалить все объекты Core Data через NSBatchDeleteRequest.
        let coordinator = container.persistentStoreCoordinator
        let model = coordinator.managedObjectModel
        var deletedCount = 0

        for entity in model.entities {
            guard let name = entity.name else { continue }
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let delete = NSBatchDeleteRequest(fetchRequest: fetch)
            delete.resultType = .resultTypeCount
            do {
                let result = try viewContext.execute(delete) as? NSBatchDeleteResult
                let n = (result?.result as? Int) ?? 0
                deletedCount += n
                Self.log.info("Wiped \(n) of \(name)")
            } catch {
                Self.log.error("Wipe \(name) failed: \(error.localizedDescription)")
            }
        }

        // 2. Сбросить in-memory context, чтобы UI получил пустые fetched results.
        viewContext.reset()

        // 3. Стереть UserDefaults для нашего bundle (preferences, mood-флаги,
        // streak, voice config — всё, что не является security/IAP).
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
            UserDefaults.standard.synchronize()
        }

        // 4. Уведомить координатор (если слушает) — пускай обновит состояние.
        NotificationCenter.default.post(name: .stilloDataWiped, object: nil)

        Self.log.info("Wipe complete: \(deletedCount) total objects deleted")
        return deletedCount
    }

    // MARK: - JSON → Core Data миграция

    /// Вызывается один раз при первом запуске после обновления.
    /// Читает старые JSON-файлы и переносит данные в Core Data.
    func migrateJSONIfNeeded() {
        let key = "stillo_json_migrated_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Self.log.warning("Documents directory not found — skipping migration")
            return
        }

        var migrated = false

        // 1. Diary episodes
        let diaryURL = docDir.appendingPathComponent("diary_episodes.json")
        if let data = try? Data(contentsOf: diaryURL),
           let episodes = try? JSONDecoder().decode([DiaryEpisode].self, from: data)
        {
            for ep in episodes {
                let cd = CDDiaryEpisode(context: viewContext)
                cd.id = ep.id
                cd.date = ep.date
                cd.intensity = Int16(ep.intensity)
                cd.notes = ep.notes
            }
            migrated = true
            Self.log.info("Migrated \(episodes.count) diary episodes")
        }

        // 2. Achievements
        let achieveURL = docDir.appendingPathComponent("achievements.json")
        if let data = try? Data(contentsOf: achieveURL),
           let achievements = try? JSONDecoder().decode([Achievement].self, from: data)
        {
            for a in achievements {
                let cd = CDAchievement(context: viewContext)
                cd.id = a.id
                cd.category = a.category.rawValue
                cd.currentProgress = Int32(a.currentProgress)
                cd.isUnlocked = a.isUnlocked
                cd.unlockedDate = a.unlockedDate
            }
            migrated = true
            Self.log.info("Migrated \(achievements.count) achievements")
        }

        // 3. Mood points
        let moodURL = docDir.appendingPathComponent("mood_points.json")
        if let data = try? Data(contentsOf: moodURL),
           let points = try? JSONDecoder().decode([MoodPoint].self, from: data)
        {
            for p in points {
                let cd = CDMoodPoint(context: viewContext)
                cd.id = p.id
                cd.date = p.date
                cd.mood = Int16(p.mood)
                cd.note = p.note
            }
            migrated = true
            Self.log.info("Migrated \(points.count) mood points")
        }

        // 4. SOS contacts
        let sosURL = docDir.appendingPathComponent("sos_contacts.json")
        if let data = try? Data(contentsOf: sosURL),
           let contacts = try? JSONDecoder().decode([SOSContact].self, from: data)
        {
            for c in contacts {
                let cd = CDSOSContact(context: viewContext)
                cd.id = c.id
                cd.name = c.name
                cd.phone = c.phone
                cd.relationship = c.relationship
                cd.notifyOnPanic = c.notifyOnPanic
            }
            migrated = true
            Self.log.info("Migrated \(contacts.count) SOS contacts")
        }

        if migrated {
            guard save() else {
                Self.log.error("Migration save failed — keeping JSON files for retry")
                viewContext.rollback()
                return
            }
            try? FileManager.default.removeItem(at: diaryURL)
            try? FileManager.default.removeItem(at: achieveURL)
            try? FileManager.default.removeItem(at: moodURL)
            try? FileManager.default.removeItem(at: sosURL)
            Self.log.info("Old JSON files removed after successful migration")
        }

        UserDefaults.standard.set(true, forKey: key)
        Self.log.info("JSON → Core Data migration completed")
    }

    // MARK: Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "Persistence")

    /// Checks whether the running binary has the iCloud entitlement.
    /// On device without the entitlement (e.g. Personal team), returns false
    /// so we avoid instantiating NSPersistentCloudKitContainer which would crash.
    private static func iCloudEntitlementAvailable() -> Bool {
        // If we can get a ubiquity container URL, the entitlement is present
        // This call returns nil instantly (no network) when entitlement is missing
        return FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Бросается после `PersistenceController.wipeAllData()`.
    /// Слушатели (AppCoordinator, ProfileHubView и т.п.) должны
    /// сбросить локальные state-кеши: name, streaks, achievements.
    static let stilloDataWiped = Notification.Name("stilloDataWiped")
}
