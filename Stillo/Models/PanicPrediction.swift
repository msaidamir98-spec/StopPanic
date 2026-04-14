import Foundation

/// Предсказание эпизода тревоги по паттернам
struct PanicPrediction: Codable, Identifiable {
    enum RiskLevel: String, Codable, CaseIterable {
        case low, moderate, high, critical

        // MARK: Internal

        var emoji: String {
            switch self { case .low: "🟢"
            case .moderate: "🟡"
            case .high: "🟠"
            case .critical: "🔴" }
        }

        var title: String {
            switch self { case .low: String(localized: "risk.low")
            case .moderate: String(localized: "risk.moderate")
            case .high: String(localized: "risk.high")
            case .critical: String(localized: "risk.critical") }
        }
    }

    let id: UUID
    let timestamp: Date
    let riskLevel: RiskLevel
    let confidence: Double // 0…1
    let triggers: [String]
    let recommendation: String
}
