import Foundation
import Combine

/// Сервис профиля пользователя
@MainActor
final class UserProfileService: ObservableObject {
    @Published var displayName: String = ""

    init() {
        displayName = UserDefaults.standard.string(forKey: "userDisplayName") ?? ""
    }

    func updateName(_ name: String) {
        displayName = name
        UserDefaults.standard.set(name, forKey: "userDisplayName")
    }
}
