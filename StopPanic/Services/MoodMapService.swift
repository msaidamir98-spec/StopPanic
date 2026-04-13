import Combine
import Foundation
import os.log

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

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "MoodMapService")

    private let storageURL: URL

    private func savePoints() {
        do {
            let data = try JSONEncoder().encode(points)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            Self.log.error("Failed to save mood points: \(error.localizedDescription)")
        }
    }

    private func loadPoints() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            points = try JSONDecoder().decode([MoodPoint].self, from: data)
        } catch {
            Self.log.error("Failed to load mood points: \(error.localizedDescription)")
        }
    }
}
