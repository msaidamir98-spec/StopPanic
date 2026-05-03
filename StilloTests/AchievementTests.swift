import Foundation
import Testing
@testable import Stillo

struct AchievementTests {
    @Test
    func allAchievementsHaveUniqueIDs() {
        let ids = Achievement.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test
    func progressClampsToOne() {
        var a = Achievement.all[0]
        a.currentProgress = a.requirement * 10
        #expect(a.progress == 1.0)
    }

    @Test
    func progressIsZeroWhenRequirementIsZero() {
        let a = Achievement(
            id: "test",
            title: "x",
            description: "x",
            icon: "x",
            category: .milestone,
            requirement: 0,
            currentProgress: 5,
            isUnlocked: false
        )
        #expect(a.progress == 0)
    }

    @Test
    func codableRoundTrip() throws {
        let original = Achievement.all[0]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Achievement.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.category == original.category)
        #expect(decoded.requirement == original.requirement)
    }

    @Test
    func categoryIsCaseIterable() {
        #expect(Achievement.Category.allCases.count == 5)
    }
}
