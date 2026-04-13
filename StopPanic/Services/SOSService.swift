import Combine
import Foundation
import os.log
import UserNotifications

/// SOS-сервис: экстренные контакты + телефоны доверия
@MainActor
final class SOSService: ObservableObject {
    // MARK: Lifecycle

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = dir.appendingPathComponent("sos_contacts.json")
        loadContacts()
    }

    // MARK: Internal

    static let crisisLines: [String: String] = [
        "RU": "8-800-2000-122", "US": "988", "UK": "116 123",
        "DE": "0800 111 0 111", "FR": "3114", "ES": "024",
        "IT": "800 274 274", "JP": "0570-064-556",
        "BR": "188", "CN": "400-161-9995",
        "PT": "808 200 204", "KR": "1393",
    ]

    @Published
    var contacts: [SOSContact] = []
    @Published
    var panicModeActive: Bool = false

    static func getCrisisLine() -> String {
        let region = Locale.current.language.region?.identifier ?? "US"
        return crisisLines[region] ?? "988"
    }

    func activateSOS() {
        // Rate limit: min 5 seconds between SOS triggers
        if let last = lastSOSDate, Date().timeIntervalSince(last) < 5 { return }
        lastSOSDate = Date()
        panicModeActive = true

        // Ensure notification permissions
        // NOTE: .criticalAlert requires a special Apple entitlement — use .sound + .badge instead
        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .sound, .badge,
        ]) { _, _ in }

        // Send local notification for each SOS contact
        for contact in contacts where contact.notifyOnPanic {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "sos.notif_title \(contact.name)")
            content.body = String(localized: "sos.notif_body \(contact.phone)")
            content.sound = .defaultCritical
            content.interruptionLevel = .timeSensitive
            let request = UNNotificationRequest(
                identifier: "sos_\(contact.id.uuidString)",
                content: content,
                trigger: nil // immediate
            )
            UNUserNotificationCenter.current().add(request)
        }

        // If no contacts, still show crisis line
        if contacts.filter(\.notifyOnPanic).isEmpty {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "sos.crisis_notif_title")
            content.body = String(localized: "sos.crisis_notif_body \(Self.getCrisisLine())")
            content.sound = .defaultCritical
            let request = UNNotificationRequest(
                identifier: "sos_crisis",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func deactivateSOS() {
        panicModeActive = false
    }

    func addContact(_ contact: SOSContact) {
        contacts.append(contact)
        saveContacts()
    }

    func removeContact(at idx: Int) {
        guard contacts.indices.contains(idx) else { return }
        contacts.remove(at: idx)
        saveContacts()
    }

    // MARK: Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "SOSService")

    private var lastSOSDate: Date?
    private let storageURL: URL

    private func saveContacts() {
        do {
            let data = try JSONEncoder().encode(contacts)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            Self.log.error("Failed to save SOS contacts: \(error.localizedDescription)")
        }
    }

    private func loadContacts() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            contacts = try JSONDecoder().decode([SOSContact].self, from: data)
        } catch {
            Self.log.error("Failed to load SOS contacts: \(error.localizedDescription)")
        }
    }
}
