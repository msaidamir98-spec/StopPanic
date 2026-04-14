import StoreKit
import SwiftUI

// MARK: - Review / Rate App Service

// Запрашивает отзыв в правильный момент — после 3+ успешных сессий.
// Apple позволяет показывать SKStoreReviewController ≤3 раз в год.

@Observable @MainActor
final class ReviewService {
    // MARK: Lifecycle

    private init() {
        completedSessions = UserDefaults.standard.integer(forKey: sessionsKey)
        lastPromptDate = UserDefaults.standard.object(forKey: lastPromptKey) as? Date
    }

    // MARK: Internal

    static let shared = ReviewService()

    var completedSessions: Int {
        didSet { UserDefaults.standard.set(completedSessions, forKey: sessionsKey) }
    }

    // MARK: - Track & Prompt

    /// Call after a successful SOS / breathing session
    func trackSessionCompleted() {
        completedSessions += 1
        attemptReviewPrompt()
    }

    func attemptReviewPrompt() {
        guard completedSessions >= minSessionsBeforePrompt else { return }

        if let last = lastPromptDate {
            let daysSince = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            guard daysSince >= daysBetweenPrompts else { return }
        }

        requestReview()
    }

    // MARK: Private

    private let sessionsKey = "ReviewService.completedSessions"
    private let lastPromptKey = "ReviewService.lastPromptDate"
    private let minSessionsBeforePrompt = 3
    private let daysBetweenPrompts = 60

    private var lastPromptDate: Date? {
        didSet { UserDefaults.standard.set(lastPromptDate, forKey: lastPromptKey) }
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }

        AppStore.requestReview(in: scene)
        lastPromptDate = Date()
    }
}
