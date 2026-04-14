import Foundation

// MARK: - HeartAnalysis

/// Результат анализа сердечного ритма
struct HeartAnalysis: Codable, Identifiable {
    /// Классификация состояния по паттерну ритма
    ///
    /// ТРЕВОЖНАЯ РЕАКЦИЯ:
    ///  • ЧСС ↑ резко, но ритм РЕГУЛЯРНЫЙ (синусовая тахикардия)
    ///  • HRV (вариабельность) СНИЖАЕТСЯ, но паттерн стабильный
    ///  • Пик за 1–3 мин, плато, затем постепенное снижение
    ///  • ЧСС обычно 100–150 BPM
    ///  • Реагирует на дыхательные техники (vagal maneuvers)
    ///
    /// ИНФАРКТ / АРИТМИЯ:
    ///  • Ритм НЕРЕГУЛЯРНЫЙ (аритмия, фибрилляция)
    ///  • HRV хаотически скачет
    ///  • Может быть брадикардия (<60) ИЛИ тахикардия (>150)
    ///  • НЕ реагирует на дыхание
    ///  • Может сопровождаться резким падением SpO2
    enum Diagnosis: String, Codable {
        case panicAttack = "anxiety"
        case likelyCardiac = "cardiac"
        case arrhythmia = "arrhythmia"
        case normal = "normal"
        case inconclusive = "collecting"

        var localizedTitle: String {
            switch self {
            case .panicAttack: String(localized: "diagnosis.anxiety")
            case .likelyCardiac: String(localized: "diagnosis.cardiac")
            case .arrhythmia: String(localized: "diagnosis.arrhythmia")
            case .normal: String(localized: "diagnosis.normal")
            case .inconclusive: String(localized: "diagnosis.collecting")
            }
        }
    }

    /// Паттерн нарастания ЧСС
    enum RisePattern: String, Codable {
        case suddenRegular = "sudden_regular"
        case suddenIrregular = "sudden_irregular"
        case gradual = "gradual"
        case noChange = "no_change"

        var localizedTitle: String {
            switch self {
            case .suddenRegular: String(localized: "pattern.sudden_regular")
            case .suddenIrregular: String(localized: "pattern.sudden_irregular")
            case .gradual: String(localized: "pattern.gradual")
            case .noChange: String(localized: "pattern.no_change")
            }
        }
    }

    let id: UUID
    let timestamp: Date
    let diagnosis: Diagnosis
    let confidence: Double // 0…1
    let heartRate: Double // BPM
    let hrvMs: Double // вариабельность ЧСС (мс)
    let irregularity: Double // 0…1 — нерегулярность ритма
    let risePattern: RisePattern
    let recommendation: String
    let suggestMedicalConsult: Bool
}

// MARK: - HeartRateSample

/// Одна точка данных ЧСС
struct HeartRateSample: Codable, Identifiable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        bpm: Double,
        hrvMs: Double? = nil,
        source: Source = .healthKit
    ) {
        self.id = id
        self.timestamp = timestamp
        self.bpm = bpm
        self.hrvMs = hrvMs
        self.source = source
    }

    // MARK: Internal

    enum Source: String, Codable {
        case appleWatch, healthKit, manual
    }

    let id: UUID
    let timestamp: Date
    let bpm: Double
    let hrvMs: Double? // вариабельность, если есть
    let source: Source
}

// MARK: - CardiacThresholds

/// Критерии различения (медицинские пороги)
enum CardiacThresholds {
    /// Если irregularity > 0.35 → подозрение на аритмию
    static let irregularityThreshold: Double = 0.35
    /// ЧСС > 150 + нерегулярный ритм → кардио-тревога
    static let dangerousHR: Double = 150
    /// HRV < 20 мс при тахикардии → тревожная реакция (зажатый ритм)
    static let lowHRV: Double = 20
    /// HRV скачет > 50 мс между ударами → подозрение на аритмию
    static let chaoticHRV: Double = 50
    /// Если дыхательная техника снизила ЧСС > 10% за 2 мин → тревога
    static let breathingResponseThreshold: Double = 0.10
}
