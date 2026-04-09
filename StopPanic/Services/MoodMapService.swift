import Combine
import Foundation

// MARK: - MoodPoint

/// Точка настроения на графике
struct MoodPoint: Codable, Identifiable {
    // MARK: Lifecycle

    init(id: UUID = UUID(), date: Date = Date(), mood: Int, note: String = "") {
        self.id = id
        self.date = date
        self.mood = mood
        self.note = note
    }

    // MARK: Internal

    let id: UUID
    let date: Date
    let mood: Int // 1-10
    let note: String
}

// MARK: - MoodMapService

/// Сервис карты настроения
@MainActor
final class MoodMapService: ObservableObject {
    // MARK: Lifecycle

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = dir.appendingPathComponent("mood_points.json")
        loadPoints()
    }

    // MARK: Internal

    @Published
    var points: [MoodPoint] = []

    func addPoint(mood: Int, note: String = "") {
        let point = MoodPoint(mood: mood, note: note)
        points.append(point)
        savePoints()
    }

    // MARK: Private

    private let storageURL: URL

    private func savePoints() {
        if let data = try? JSONEncoder().encode(points) {
            try? data.write(to: storageURL)
        }
    }

    private func loadPoints() {
        if let data = try? Data(contentsOf: storageURL),
           let loaded = try? JSONDecoder().decode([MoodPoint].self, from: data)
        {
            points = loaded
        }
    }
}
