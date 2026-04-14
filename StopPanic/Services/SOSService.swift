import Combine
import CoreData
import Foundation
import os.log
import UserNotifications

/// SOS-сервис: экстренные контакты + телефоны доверия (Core Data + CloudKit)
@MainActor
final class SOSService: ObservableObject {
    // MARK: Lifecycle

    init() {
        persistence = PersistenceController.shared
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

        UNUserNotificationCenter.current().requestAuthorization(options: [
            .alert, .sound, .badge,
        ]) { _, _ in }

        // Send local notification for each SOS contact
        for contact in contacts where contact.notifyOnPanic {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "sos.notif_title \(contact.name)")
            content.body = String(localized: "sos.notif_body \(contact.phone)")
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            let request = UNNotificationRequest(
                identifier: "sos_\(contact.id.uuidString)",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }

        // If no contacts, still show crisis line
        if contacts.filter(\.notifyOnPanic).isEmpty {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "sos.crisis_notif_title")
            content.body = String(localized: "sos.crisis_notif_body \(Self.getCrisisLine())")
            content.sound = .default
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

        let cd = CDSOSContact(context: persistence.viewContext)
        cd.id = contact.id
        cd.name = contact.name
        cd.phone = contact.phone
        cd.relationship = contact.relationship
        cd.notifyOnPanic = contact.notifyOnPanic
        persistence.save()
    }

    func removeContact(at idx: Int) {
        guard contacts.indices.contains(idx) else { return }
        let contact = contacts.remove(at: idx)

        let request: NSFetchRequest<CDSOSContact> = CDSOSContact.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", contact.id as CVarArg)
        if let results = try? persistence.viewContext.fetch(request),
           let obj = results.first
        {
            persistence.viewContext.delete(obj)
            persistence.save()
        }
    }

    // MARK: Private

    private static let log = Logger(
        subsystem: "MSK-PRODUKT.StopPanic",
        category: "SOSService"
    )
    private var lastSOSDate: Date?
    private let persistence: PersistenceController

    private func loadContacts() {
        let request: NSFetchRequest<CDSOSContact> = CDSOSContact.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CDSOSContact.name, ascending: true),
        ]
        do {
            let results = try persistence.viewContext.fetch(request)
            contacts = results.map {
                SOSContact(
                    id: $0.id ?? UUID(),
                    name: $0.name ?? "",
                    phone: $0.phone ?? "",
                    relationship: $0.relationship ?? "",
                    notifyOnPanic: $0.notifyOnPanic
                )
            }
        } catch {
            Self.log.error(
                "Failed to load SOS contacts: \(error.localizedDescription)"
            )
        }
    }
}
