import Combine
import Foundation

/// Сервис профиля пользователя
/// Source of truth — UserDefaults ключ "userName" (совпадает с AppCoordinator)
@MainActor
final class UserProfileService: ObservableObject {
    // MARK: Lifecycle

    init() {
        displayName = UserDefaults.standard.string(forKey: "userName") ?? ""
    }

    // MARK: Internal

    @Published
    var displayName: String = "" {
        didSet {
            UserDefaults.standard.set(displayName, forKey: "userName")
        }
    }

    func updateName(_ name: String) {
        displayName = name
    }
}
