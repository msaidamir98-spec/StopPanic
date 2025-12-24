import Foundation
import Combine

/// Хранилище дневника панических атак
@MainActor
final class DiaryService: ObservableObject {
    @Published var diaryEpisodes: [DiaryEpisode] = []

    private let storageURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = dir.appendingPathComponent("diary_episodes.json")
        loadEpisodes()
    }

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

    private func saveEpisodes() {
        if let data = try? JSONEncoder().encode(diaryEpisodes) {
            try? data.write(to: storageURL)
        }
    }

    private func loadEpisodes() {
        if let data = try? Data(contentsOf: storageURL),
           let loaded = try? JSONDecoder().decode([DiaryEpisode].self, from: data) {
            diaryEpisodes = loaded
        }
    }
}
