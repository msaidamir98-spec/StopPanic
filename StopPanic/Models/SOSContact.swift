import Foundation

/// Экстренный контакт для SOS-функции
struct SOSContact: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var phone: String
    var relationship: String
    var notifyOnPanic: Bool

    init(id: UUID = UUID(), name: String, phone: String,
         relationship: String, notifyOnPanic: Bool = true) {
        self.id = id; self.name = name; self.phone = phone
        self.relationship = relationship
        self.notifyOnPanic = notifyOnPanic
    }
}
