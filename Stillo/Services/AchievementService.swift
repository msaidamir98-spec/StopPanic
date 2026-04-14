import Combine
import CoreData
import Foundation
import os.log
import SwiftUI

/// Система достижений и геймификации (Core Data + CloudKit)
@MainActor
final class AchievementService: ObservableObject {
    // MARK: Lifecycle

    init() {
        persistence = PersistenceController.shared
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
        saveAchievement(achievements[idx])
    }

    // MARK: Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "AchievementService")

    private let persistence: PersistenceController

    private func saveAchievement(_ achievement: Achievement) {
        let request: NSFetchRequest<CDAchievement> = CDAchievement.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", achievement.id)

        let cd: CDAchievement
        if let existing = try? persistence.viewContext.fetch(request).first {
            cd = existing
        } else {
            cd = CDAchievement(context: persistence.viewContext)
            cd.id = achievement.id
        }
        cd.category = achievement.category.rawValue
        cd.currentProgress = Int32(achievement.currentProgress)
        cd.isUnlocked = achievement.isUnlocked
        cd.unlockedDate = achievement.unlockedDate
        persistence.save()
    }

    private func loadAchievements() {
        let request: NSFetchRequest<CDAchievement> = CDAchievement.fetchRequest()
        guard let results = try? persistence.viewContext.fetch(request), !results.isEmpty else { return }

        // Сливаем прогресс из Core Data в шаблоны Achievement.all
        let cdMap = Dictionary(uniqueKeysWithValues: results.compactMap { cd -> (String, CDAchievement)? in
            guard let id = cd.id else { return nil }
            return (id, cd)
        })

        for idx in achievements.indices {
            if let cd = cdMap[achievements[idx].id] {
                achievements[idx].currentProgress = Int(cd.currentProgress)
                achievements[idx].isUnlocked = cd.isUnlocked
                achievements[idx].unlockedDate = cd.unlockedDate
            }
        }
        totalPoints = achievements.filter(\.isUnlocked).count * 100
    }
}
