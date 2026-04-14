import Foundation

// MARK: - HeartAnalysis

/// Результат анализа сердечного ритма (информационный, НЕ медицинский)
struct HeartAnalysis: Codable, Identifiable {
    /// Классификация паттерна пульса (wellness, НЕ диагностика)
    ///
    /// СТРЕСС / ТРЕВОГА:
    ///  • ЧСС ↑ резко, но ритм РЕГУЛЯРНЫЙ
    ///  • HRV (вариабельность) снижается равномерно
    ///  • Пик за 1–3 мин, плато, затем постепенное снижение
    ///  • ЧСС обычно 100–150 BPM
    ///  • Реагирует на дыхательные техники
    ///
    /// НЕРЕГУЛЯРНЫЙ ПАТТЕРН:
    ///  • Ритм нерегулярный
    ///  • HRV хаотически скачет
    ///  • Может быть <60 или >150
    ///  • НЕ реагирует на дыхание
    ///  • Рекомендуется консультация врача
    enum Diagnosis: String, Codable {
        case stressResponse = "anxiety"
        case elevatedIrregular = "cardiac"
        case irregularPattern = "arrhythmia" // backward-compatible raw values
        case normal
        case inconclusive = "collecting"

        // MARK: Internal

        var localizedTitle: String {
            switch self {
            case .stressResponse: String(localized: "diagnosis.stress_response")
            case .elevatedIrregular: String(localized: "diagnosis.elevated_irregular")
            case .irregularPattern: String(localized: "diagnosis.irregular_pattern")
            case .normal: String(localized: "diagnosis.normal")
            case .inconclusive: String(localized: "diagnosis.collecting")
            }
        }
    }

    /// Паттерн нарастания ЧСС
    enum RisePattern: String, Codable {
        case suddenRegular = "sudden_regular"
        case suddenIrregular = "sudden_irregular"
        case gradual
        case noChange = "no_change"

        // MARK: Internal

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

// MARK: - HeartRateThresholds

/// Пороги для паттернового анализа (wellness, не клинические)
enum HeartRateThresholds {
    /// Если irregularity > 0.35 → нерегулярный паттерн
    static let irregularityThreshold: Double = 0.35
    /// ЧСС > 150 + нерегулярный ритм → рекомендация обратиться к врачу
    static let elevatedHR: Double = 150
    /// HRV < 20 мс при тахикардии → стрессовая реакция (зажатый ритм)
    static let lowHRV: Double = 20
    /// HRV скачет > 50 мс между ударами → нерегулярный паттерн
    static let chaoticHRV: Double = 50
    /// Если дыхательная техника снизила ЧСС > 10% за 2 мин → стрессовая реакция
    static let breathingResponseThreshold: Double = 0.10
}
