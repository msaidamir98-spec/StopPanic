import Foundation

/// Сообщение в AI-чате терапевта
struct AIMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let role: Role
    let timestamp: Date
    let technique: TherapyTechnique?

    enum Role: String, Codable {
        case user, assistant, system
    }

    enum TherapyTechnique: String, Codable, CaseIterable {
        case cbt       = "CBT"
        case act       = "ACT"
        case dbt       = "DBT"
        case grounding = "Заземление"
        case breathwork = "Дыхание"
        case emdr      = "EMDR"
    }

    init(id: UUID = UUID(), content: String, role: Role,
         timestamp: Date = Date(), technique: TherapyTechnique? = nil) {
        self.id = id; self.content = content; self.role = role
        self.timestamp = timestamp; self.technique = technique
    }
}
