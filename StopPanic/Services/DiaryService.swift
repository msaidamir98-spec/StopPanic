import Combine
import Foundation
import os.log

/// Хранилище дневника тревожных эпизодов
@MainActor
final class DiaryService: ObservableObject {
    // MARK: Lifecycle

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = dir.appendingPathComponent("diary_episodes.json")
        loadEpisodes()
    }

    // MARK: Internal

    @Published
    var diaryEpisodes: [DiaryEpisode] = []

    func addDiaryEpisode(intensity: Int, notes: String) {
        let episode = DiaryEpisode(intensity: intensity, notes: notes)
        diaryEpisodes.append(episode)
        saveEpisodes()
    }

    func removeEpisode(at index: Int) {
        guard diaryEpisodes.indices.contains(index) else { return }
        diaryEpisodes.remove(at: index)
        saveEpisodes()
    }

    // MARK: Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "DiaryService")

    private let storageURL: URL

    /// Public alias for background save
    func forceSave() {
        saveEpisodes()
    }

    private func saveEpisodes() {
        do {
            let data = try JSONEncoder().encode(diaryEpisodes)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            Self.log.error("Failed to save diary: \(error.localizedDescription)")
        }
    }

    private func loadEpisodes() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            diaryEpisodes = try JSONDecoder().decode([DiaryEpisode].self, from: data)
        } catch {
            Self.log.error("Failed to load diary: \(error.localizedDescription)")
        }
    }
}
