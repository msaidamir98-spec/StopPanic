import Combine
import Foundation
import UserNotifications

/// SOS-сервис: экстренные контакты + телефоны доверия
@MainActor
final class SOSService: ObservableObject {
    @Published var contacts: [SOSContact] = []
    @Published var panicModeActive: Bool = false
    private var lastSOSDate: Date?

    static let crisisLines: [String: String] = [
        "RU": "8-800-2000-122", "US": "988", "UK": "116 123",
        "DE": "0800 111 0 111", "FR": "3114", "ES": "024",
        "IT": "800 274 274", "JP": "0570-064-556",
    ]

    private let storageURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = dir.appendingPathComponent("sos_contacts.json")
        loadContacts()
    }

    func activateSOS() {
        // Rate limit: min 5 seconds between SOS triggers
        if let last = lastSOSDate, Date().timeIntervalSince(last) < 5 { return }
        lastSOSDate = Date()
        panicModeActive = true

        // Ensure notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .sound, .criticalAlert,
        ]) { _, _ in }

        // Send local notification for each SOS contact
        for contact in contacts where contact.notifyOnPanic {
            let content = UNMutableNotificationContent()
            content.title = "🆘 SOS — \(contact.name)"
            content.body = "Паническая атака. Позвони: \(contact.phone)"
            content.sound = .defaultCritical
            content.interruptionLevel = .critical
            let request = UNNotificationRequest(
                identifier: "sos_\(contact.id.uuidString)",
                content: content,
                trigger: nil  // immediate
            )
            UNUserNotificationCenter.current().add(request)
        }

        // If no contacts, still show crisis line
        if contacts.filter(\.notifyOnPanic).isEmpty {
            let content = UNMutableNotificationContent()
            content.title = "🆘 Паническая атака"
            content.body = "Телефон доверия: \(SOSService.getCrisisLine())"
            content.sound = .defaultCritical
            let request = UNNotificationRequest(
                identifier: "sos_crisis",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func deactivateSOS() { panicModeActive = false }

    func addContact(_ contact: SOSContact) {
        contacts.append(contact)
        saveContacts()
    }

    func removeContact(at idx: Int) {
        guard contacts.indices.contains(idx) else { return }
        contacts.remove(at: idx)
        saveContacts()
    }

    static func getCrisisLine() -> String {
        let region = Locale.current.language.region?.identifier ?? "US"
        return crisisLines[region] ?? "988"
    }

    private func saveContacts() {
        if let data = try? JSONEncoder().encode(contacts) {
            try? data.write(to: storageURL)
        }
    }

    private func loadContacts() {
        if let data = try? Data(contentsOf: storageURL),
            let loaded = try? JSONDecoder().decode([SOSContact].self, from: data)
        {
            contacts = loaded
        }
    }
}
