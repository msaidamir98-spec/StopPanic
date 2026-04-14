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
        container = NSPersistentCloudKitContainer(name: "Stillo")

        // CloudKit конфигурация
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No persistent store descriptions found")
        }
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.MSK-PRODUKT.StopPanic"
        )

        // Включаем автоматический merge из CloudKit
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { _, error in
            if let error {
                Self.log.error("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Подписка на удалённые изменения
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            self?.container.viewContext.perform {
                // Автоматический merge уже включен, но можно добавить логику обновления UI
                Self.log.info("Received remote CloudKit change")
            }
        }
    }

    // MARK: Internal

    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let ctx = viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            Self.log.error("Core Data save failed: \(error.localizedDescription)")
        }
    }

    // MARK: - JSON → Core Data миграция

    /// Вызывается один раз при первом запуске после обновления.
    /// Читает старые JSON-файлы и переносит данные в Core Data.
    func migrateJSONIfNeeded() {
        let key = "stillo_json_migrated_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
            save()
            // Удаляем старые JSON-файлы после успешной миграции
            try? FileManager.default.removeItem(at: diaryURL)
            try? FileManager.default.removeItem(at: achieveURL)
            try? FileManager.default.removeItem(at: moodURL)
            try? FileManager.default.removeItem(at: sosURL)
            Self.log.info("Old JSON files removed after migration")
        }

        UserDefaults.standard.set(true, forKey: key)
        Self.log.info("JSON → Core Data migration completed")
    }

    // MARK: Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "Persistence")
}
