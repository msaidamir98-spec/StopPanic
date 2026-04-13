import Combine
import Foundation
import os.log
import SwiftUI

/// Система достижений и геймификации
@MainActor
final class AchievementService: ObservableObject {
    // MARK: Lifecycle

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = dir.appendingPathComponent("achievements.json")
        loadAchievements()
    }

    // MARK: Internal

    @Published
    var achievements: [Achievement] = Achievement.all
    @Published
    var newlyUnlocked: Achievement?
    @Published
    var totalPoints: Int = 0

    func updateProgress(id: String, increment: Int = 1) {
        guard let idx = achievements.firstIndex(where: { $0.id == id }) else { return }
        achievements[idx].currentProgress += increment

        if achievements[idx].currentProgress >= achievements[idx].requirement,
           !achievements[idx].isUnlocked
        {
            achievements[idx].isUnlocked = true
            achievements[idx].unlockedDate = Date()
            newlyUnlocked = achievements[idx]
        }
        totalPoints = achievements.filter(\.isUnlocked).count * 100
        saveAchievements()
    }

    // MARK: Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "AchievementService")

    private let storageURL: URL

    private func saveAchievements() {
        do {
            let data = try JSONEncoder().encode(achievements)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            Self.log.error("Failed to save achievements: \(error.localizedDescription)")
        }
    }

    private func loadAchievements() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let loaded = try JSONDecoder().decode([Achievement].self, from: data)
            achievements = loaded
            totalPoints = loaded.filter(\.isUnlocked).count * 100
        } catch {
            Self.log.error("Failed to load achievements: \(error.localizedDescription)")
        }
    }
}
