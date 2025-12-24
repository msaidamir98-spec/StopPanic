import Foundation
import Combine

/// Точка настроения на графике
struct MoodPoint: Codable, Identifiable {
    let id: UUID
    let date: Date
    let mood: Int           // 1-10
    let note: String

    init(id: UUID = UUID(), date: Date = Date(), mood: Int, note: String = "") {
        self.id = id; self.date = date; self.mood = mood; self.note = note
    }
}

/// Сервис карты настроения
@MainActor
final class MoodMapService: ObservableObject {
    @Published var points: [MoodPoint] = []

    private let storageURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = dir.appendingPathComponent("mood_points.json")
        loadPoints()
    }

    func addPoint(mood: Int, note: String = "") {
        let point = MoodPoint(mood: mood, note: note)
        points.append(point)
        savePoints()
    }

    private func savePoints() {
        if let data = try? JSONEncoder().encode(points) {
            try? data.write(to: storageURL)
        }
    }

    private func loadPoints() {
        if let data = try? Data(contentsOf: storageURL),
           let loaded = try? JSONDecoder().decode([MoodPoint].self, from: data) {
            points = loaded
        }
    }
}
