import Foundation

/// Предсказание панической атаки по паттернам
struct PanicPrediction: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let riskLevel: RiskLevel
    let confidence: Double            // 0…1
    let triggers: [String]
    let recommendation: String

    enum RiskLevel: String, Codable, CaseIterable {
        case low, moderate, high, critical

        var emoji: String {
            switch self { case .low: "🟢"; case .moderate: "🟡"; case .high: "🟠"; case .critical: "🔴" }
        }
        var title: String {
            switch self { case .low: "Низкий"; case .moderate: "Умеренный"; case .high: "Повышенный"; case .critical: "Критический" }
        }
    }
}
