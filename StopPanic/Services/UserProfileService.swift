import Combine
import Foundation

/// Сервис профиля пользователя
@MainActor
final class UserProfileService: ObservableObject {
    // MARK: Lifecycle

    init() {
        displayName = UserDefaults.standard.string(forKey: "userDisplayName") ?? ""
    }

    // MARK: Internal

    @Published
    var displayName: String = ""

    func updateName(_ name: String) {
        displayName = name
        UserDefaults.standard.set(name, forKey: "userDisplayName")
    }
}
