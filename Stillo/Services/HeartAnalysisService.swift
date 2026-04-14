import Combine
import Foundation
import HealthKit

// MARK: - Анализ паттернов пульса (wellness / информационный)

//
// Научная база (информационная, НЕ медицинская диагностика):
//  1. При стрессе — синусовая тахикардия: ритм регулярный, HRV снижен равномерно
//  2. При нерегулярном паттерне — ритм хаотичный, HRV непредсказуем
//  3. Стресс отвечает на дыхательные техники, нерегулярный паттерн — нет
//  4. Стресс: ЧСС 100-150, пик за 1-3 мин, снижение за 10-20 мин
//  5. Нерегулярный паттерн: ЧСС может быть <60 или >150, нет чёткого пика
//
// ⚠️ DISCLAIMER: Это НЕ замена медицинской диагностики.
//    Всегда рекомендуем обратиться к врачу при любых подозрениях.

@MainActor
final class HeartAnalysisService: ObservableObject {
    // MARK: Internal

    // MARK: - Published state

    @Published
    var currentAnalysis: HeartAnalysis?
    @Published
    var recentSamples: [HeartRateSample] = []
    @Published
    var isMonitoring: Bool = false
    @Published
    var breathingResponseDetected: Bool = false

    // MARK: - Public API

    /// Начать мониторинг ЧСС в реальном времени
    func startMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        else { return }

        let readTypes: Set<HKObjectType> = [hrType, hrvType]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] ok, _ in
            guard ok else { return }
            Task { @MainActor [weak self] in
                self?.beginLiveQuery()
            }
        }
    }

    /// Остановить мониторинг
    func stopMonitoring() {
        if let q = anchoredQuery { healthStore.stop(q) }
        anchoredQuery = nil
        isMonitoring = false
    }

    /// Запомнить ЧСС до начала дыхательной техники
    func markPreBreathingHR() {
        preBreathingHR = sampleBuffer.last?.bpm
    }

    /// Проверить, снизился ли пульс после дыхания
    func checkBreathingResponse() {
        guard let pre = preBreathingHR,
              let current = sampleBuffer.last?.bpm,
              pre > 0
        else { return }
        let drop = (pre - current) / pre
        breathingResponseDetected = drop >= HeartRateThresholds.breathingResponseThreshold
    }

    /// Одноразовый анализ по массиву данных
    func analyze(samples: [HeartRateSample]) -> HeartAnalysis {
        performAnalysis(samples)
    }

    // MARK: Private

    private let healthStore = HKHealthStore()
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var sampleBuffer: [HeartRateSample] = [] // окно 5 мин
    private var preBreathingHR: Double?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Live query

    private func beginLiveQuery() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let now = Date()

        let predicate = HKQuery.predicateForSamples(
            withStart: now, end: nil, options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, added, _, _, _ in
            let samples = added ?? []
            Task { @MainActor [weak self] in
                self?.processSamples(samples)
            }
        }

        query.updateHandler = { [weak self] _, added, _, _, _ in
            let samples = added ?? []
            Task { @MainActor [weak self] in
                self?.processSamples(samples)
            }
        }

        healthStore.execute(query)
        anchoredQuery = query
        isMonitoring = true
    }

    private func processSamples(_ samples: [HKSample]) {
        let unit = HKUnit.count().unitDivided(by: .minute())

        let newPoints: [HeartRateSample] = samples.compactMap { s in
            guard let q = s as? HKQuantitySample else { return nil }
            return HeartRateSample(
                timestamp: q.startDate,
                bpm: q.quantity.doubleValue(for: unit),
                source: .appleWatch
            )
        }

        sampleBuffer.append(contentsOf: newPoints)
        recentSamples = sampleBuffer

        // Удаляем данные старше 5 минут
        let cutoff = Date().addingTimeInterval(-300)
        sampleBuffer.removeAll { $0.timestamp < cutoff }

        // Автоанализ при достаточном количестве данных
        if sampleBuffer.count >= 10 {
            currentAnalysis = performAnalysis(sampleBuffer)
        }
    }

    // MARK: - Алгоритм анализа

    private func performAnalysis(_ samples: [HeartRateSample]) -> HeartAnalysis {
        guard samples.count >= 3 else {
            return HeartAnalysis(
                id: UUID(), timestamp: Date(),
                diagnosis: .inconclusive, confidence: 0.1,
                heartRate: samples.last?.bpm ?? 0, hrvMs: 0,
                irregularity: 0, risePattern: .noChange,
                recommendation: String(localized: "heart.rec_collecting"),
                suggestMedicalConsult: false
            )
        }

        let bpms = samples.map(\.bpm)
        let avgBPM = bpms.reduce(0, +) / Double(bpms.count)
        let maxBPM = bpms.max() ?? 0
        let lastBPM = bpms.last ?? 0

        // 1. Рассчитываем нерегулярность (RMSSD)
        let irregularity = calculateIrregularity(bpms)

        // 2. Вариабельность ЧСС (HRV)
        let hrvEstimate = calculateHRVEstimate(bpms)

        // 3. Паттерн нарастания
        let risePattern = detectRisePattern(bpms)

        // 4. Классификация
        let (diagnosis, confidence, shouldConsult) = classify(
            avgBPM: avgBPM, maxBPM: maxBPM, lastBPM: lastBPM,
            irregularity: irregularity, hrv: hrvEstimate,
            risePattern: risePattern
        )

        // 5. Рекомендация
        let recommendation = generateRecommendation(
            diagnosis: diagnosis, avgBPM: avgBPM,
            irregularity: irregularity, breathingHelped: breathingResponseDetected
        )

        return HeartAnalysis(
            id: UUID(), timestamp: Date(),
            diagnosis: diagnosis, confidence: confidence,
            heartRate: lastBPM, hrvMs: hrvEstimate,
            irregularity: irregularity, risePattern: risePattern,
            recommendation: recommendation,
            suggestMedicalConsult: shouldConsult
        )
    }

    // MARK: - Метрики

    /// Нерегулярность ритма (0 = ровный, 1 = хаотичный)
    private func calculateIrregularity(_ bpms: [Double]) -> Double {
        guard bpms.count >= 3 else { return 0 }
        var diffs: [Double] = []
        for i in 1 ..< bpms.count {
            diffs.append(abs(bpms[i] - bpms[i - 1]))
        }
        let avgDiff = diffs.reduce(0, +) / Double(diffs.count)
        let avgBPM = bpms.reduce(0, +) / Double(bpms.count)
        guard avgBPM > 0 else { return 0 }
        return min(avgDiff / avgBPM, 1.0)
    }

    /// Оценка HRV на основе вариации RR-интервалов
    private func calculateHRVEstimate(_ bpms: [Double]) -> Double {
        guard bpms.count >= 3 else { return 0 }
        let rrIntervals = bpms.map { 60_000.0 / max($0, 1) }
        var squaredDiffs: [Double] = []
        for i in 1 ..< rrIntervals.count {
            let diff = rrIntervals[i] - rrIntervals[i - 1]
            squaredDiffs.append(diff * diff)
        }
        return sqrt(squaredDiffs.reduce(0, +) / Double(squaredDiffs.count))
    }

    /// Определение паттерна нарастания ЧСС
    private func detectRisePattern(_ bpms: [Double]) -> HeartAnalysis.RisePattern {
        guard bpms.count >= 5 else { return .noChange }

        let first3 = Array(bpms.prefix(3))
        let last3 = Array(bpms.suffix(3))
        let avgFirst = first3.reduce(0, +) / Double(first3.count)
        let avgLast = last3.reduce(0, +) / Double(last3.count)
        let change = avgLast - avgFirst

        let irregularity = calculateIrregularity(bpms)

        if abs(change) < 5 {
            return .noChange
        } else if change > 15, irregularity < 0.2 {
            return .suddenRegular
        } else if change > 15, irregularity >= 0.2 {
            return .suddenIrregular
        } else {
            return .gradual
        }
    }

    // MARK: - Классификация паттернов

    private func classify(
        avgBPM: Double,
        maxBPM: Double,
        lastBPM: Double,
        irregularity: Double,
        hrv: Double,
        risePattern: HeartAnalysis.RisePattern
    )
        -> (HeartAnalysis.Diagnosis, Double, Bool)
    {
        // 🔴 Нерегулярный + повышенный → рекомендовать врача
        // FIX: explicit parentheses to avoid operator precedence ambiguity
        if irregularity > HeartRateThresholds.irregularityThreshold,
           maxBPM > HeartRateThresholds.elevatedHR || lastBPM < 50
        {
            return (.elevatedIrregular, 0.75, true)
        }

        // 🟠 Нерегулярный паттерн
        if irregularity > HeartRateThresholds.irregularityThreshold,
           hrv > HeartRateThresholds.chaoticHRV
        {
            return (.irregularPattern, 0.65, true)
        }

        // 🟡 Стрессовая реакция
        if risePattern == .suddenRegular,
           avgBPM >= 90, avgBPM <= 160,
           irregularity < HeartRateThresholds.irregularityThreshold,
           hrv < HeartRateThresholds.lowHRV
        {
            return (.stressResponse, 0.80, false)
        }

        // Повышенный но нечёткий паттерн
        if avgBPM > 100, irregularity < 0.25 {
            return (.stressResponse, 0.55, false)
        }

        // Нормальный ритм
        if avgBPM >= 55, avgBPM <= 100, irregularity < 0.15 {
            return (.normal, 0.85, false)
        }

        return (.inconclusive, 0.3, false)
    }

    // MARK: - Рекомендации

    private func generateRecommendation(
        diagnosis: HeartAnalysis.Diagnosis,
        avgBPM: Double,
        irregularity: Double,
        breathingHelped: Bool
    ) -> String {
        let bpm = Int(avgBPM)
        switch diagnosis {
        case .stressResponse:
            if breathingHelped {
                return String(localized: "heart.rec_stress_breathing_helped")
            }
            return String(localized: "heart.rec_stress \(bpm)")

        case .elevatedIrregular:
            return String(localized: "heart.rec_irregular_elevated \(bpm)")

        case .irregularPattern:
            return String(localized: "heart.rec_irregular_pattern")

        case .normal:
            return String(localized: "heart.rec_normal \(bpm)")

        case .inconclusive:
            return String(localized: "heart.rec_collecting")
        }
    }
}
