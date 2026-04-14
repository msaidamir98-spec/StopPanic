import Combine
import CoreData
import Foundation
import os.log

/// Хранилище дневника тревожных эпизодов (Core Data + CloudKit)
@MainActor
final class DiaryService: ObservableObject {
    // MARK: Lifecycle

    init() {
        persistence = PersistenceController.shared
        loadEpisodes()
    }

    // MARK: Internal

    @Published
    var diaryEpisodes: [DiaryEpisode] = []

    func addDiaryEpisode(intensity: Int, notes: String) {
        let episode = DiaryEpisode(intensity: intensity, notes: notes)
        diaryEpisodes.append(episode)

        let cd = CDDiaryEpisode(context: persistence.viewContext)
        cd.id = episode.id
        cd.date = episode.date
        cd.intensity = Int16(episode.intensity)
        cd.notes = episode.notes
        persistence.save()
    }

    func removeEpisode(at index: Int) {
        guard diaryEpisodes.indices.contains(index) else { return }
        let episode = diaryEpisodes.remove(at: index)

        let request: NSFetchRequest<CDDiaryEpisode> = CDDiaryEpisode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", episode.id as CVarArg)
        if let results = try? persistence.viewContext.fetch(request), let obj = results.first {
            persistence.viewContext.delete(obj)
            persistence.save()
        }
    }

    /// Публичный алиас для сохранения (background)
    func forceSave() {
        persistence.save()
    }

    // MARK: Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "DiaryService")

    private let persistence: PersistenceController

    private func loadEpisodes() {
        let request: NSFetchRequest<CDDiaryEpisode> = CDDiaryEpisode.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDiaryEpisode.date, ascending: true)]
        do {
            let results = try persistence.viewContext.fetch(request)
            diaryEpisodes = results.map {
                DiaryEpisode(
                    id: $0.id ?? UUID(),
                    date: $0.date ?? Date(),
                    intensity: Int($0.intensity),
                    notes: $0.notes ?? ""
                )
            }
        } catch {
            Self.log.error("Failed to load diary from Core Data: \(error.localizedDescription)")
        }
    }
}
