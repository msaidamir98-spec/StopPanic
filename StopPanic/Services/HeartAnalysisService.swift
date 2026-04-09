import Combine
import Foundation
import HealthKit

// MARK: - Медицинский анализатор: Паническая Атака vs Инфаркт

//
// Научная база:
//  1. При ПА — синусовая тахикардия: ритм РЕГУЛЯРНЫЙ, HRV снижен равномерно
//  2. При инфаркте/аритмии — ритм НЕРЕГУЛЯРНЫЙ, HRV хаотичен
//  3. ПА отвечает на vagal maneuvers (дыхание 4-7-8), кардио — нет
//  4. ПА: ЧСС 100-150, пик за 1-3 мин, снижение за 10-20 мин
//  5. Кардио: ЧСС может быть <60 (брадикардия) или >150, нет чёткого пика
//
// ⚠️ DISCLAIMER: Это НЕ замена медицинской диагностики.
//    Всегда рекомендуем обратиться к врачу при подозрении на сердечную проблему.

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

        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

        let readTypes: Set<HKObjectType> = [hrType, hrvType]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] ok, _ in
            guard ok, let self else { return }
            Task { @MainActor in
                self.beginLiveQuery()
            }
        }
    }

    /// Остановить мониторинг
    func stopMonitoring() {
        if let q = anchoredQuery { healthStore.stop(q) }
        anchoredQuery = nil
        isMonitoring = false
    }

    /// Запомнить ЧСС до начала дыхательной техники (для проверки vagal response)
    func markPreBreathingHR() {
        preBreathingHR = sampleBuffer.last?.bpm
    }

    /// Проверить, снизился ли пульс после дыхания (→ вероятна ПА)
    func checkBreathingResponse() {
        guard let pre = preBreathingHR,
              let current = sampleBuffer.last?.bpm,
              pre > 0
        else { return }
        let drop = (pre - current) / pre
        breathingResponseDetected = drop >= CardiacThresholds.breathingResponseThreshold
    }

    /// Одноразовый анализ по массиву данных (ручной или из дневника)
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
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
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
            guard let self else { return }
            let samples = added ?? []
            Task { @MainActor in
                self.processSamples(samples)
            }
        }

        query.updateHandler = { [weak self] _, added, _, _, _ in
            guard let self else { return }
            let samples = added ?? []
            Task { @MainActor in
                self.processSamples(samples)
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

        Task { @MainActor in
            self.sampleBuffer.append(contentsOf: newPoints)
            self.recentSamples = self.sampleBuffer

            // Удаляем данные старше 5 минут
            let cutoff = Date().addingTimeInterval(-300)
            self.sampleBuffer.removeAll { $0.timestamp < cutoff }

            // Автоанализ при достаточном количестве данных
            if self.sampleBuffer.count >= 10 {
                self.currentAnalysis = self.performAnalysis(self.sampleBuffer)
            }
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
                recommendation: "Недостаточно данных. Подождите 30 секунд.",
                shouldCallEmergency: false
            )
        }

        let bpms = samples.map(\.bpm)
        let avgBPM = bpms.reduce(0, +) / Double(bpms.count)
        let maxBPM = bpms.max() ?? 0
        let lastBPM = bpms.last ?? 0

        // 1. Рассчитываем нерегулярность (RMSSD — стандартная метрика)
        let irregularity = calculateIrregularity(bpms)

        // 2. Вариабельность ЧСС (HRV)
        let hrvEstimate = calculateHRVEstimate(bpms)

        // 3. Паттерн нарастания
        let risePattern = detectRisePattern(bpms)

        // 4. Классификация
        let (diagnosis, confidence, shouldCall) = classify(
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
            shouldCallEmergency: shouldCall
        )
    }

    // MARK: - Метрики

    /// Нерегулярность ритма (0 = идеально ровный, 1 = хаотичный)
    /// При ПА — низкая (< 0.2), при аритмии — высокая (> 0.35)
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
        // Переводим BPM → RR интервалы (мс)
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
            return .suddenRegular // Типично для ПА
        } else if change > 15, irregularity >= 0.2 {
            return .suddenIrregular // Подозрение на кардио
        } else {
            return .gradual
        }
    }

    // MARK: - Классификация

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
        // 🔴 КРИТЕРИИ КАРДИО-ТРЕВОГИ (звонить 103/112)
        if irregularity > CardiacThresholds.irregularityThreshold,
           maxBPM > CardiacThresholds.dangerousHR || lastBPM < 50
        {
            return (.likelyCardiac, 0.75, true)
        }

        // 🟠 Аритмия
        if irregularity > CardiacThresholds.irregularityThreshold,
           hrv > CardiacThresholds.chaoticHRV
        {
            return (.arrhythmia, 0.65, true)
        }

        // 🟡 Паническая атака
        if risePattern == .suddenRegular,
           avgBPM >= 90, avgBPM <= 160,
           irregularity < CardiacThresholds.irregularityThreshold,
           hrv < CardiacThresholds.lowHRV
        {
            return (.panicAttack, 0.80, false)
        }

        // Тахикардия но нечёткий паттерн
        if avgBPM > 100, irregularity < 0.25 {
            return (.panicAttack, 0.55, false)
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
        switch diagnosis {
        case .panicAttack:
            if breathingHelped {
                return """
                ✅ Ваш пульс реагирует на дыхание — это подтверждает паническую атаку, \
                а не сердечную проблему. Продолжайте дыхание 4-7-8. Приступ пройдёт \
                через несколько минут. Вы в безопасности.
                """
            }
            return """
            🟡 Похоже на паническую атаку: ритм регулярный, ЧСС \(Int(avgBPM)) BPM. \
            Попробуйте дыхание 4-7-8. Если пульс снизится — это ПА. \
            Если нет или появилась боль в груди — вызовите скорую.
            """

        case .likelyCardiac:
            return """
            🔴 ВНИМАНИЕ: Обнаружен нерегулярный ритм с ЧСС \(Int(avgBPM)) BPM. \
            Это может указывать на сердечную проблему. \
            НЕМЕДЛЕННО вызовите скорую (103/112). \
            Сядьте, не двигайтесь, расстегните одежду.
            """

        case .arrhythmia:
            return """
            🟠 Обнаружена нерегулярность сердечного ритма. \
            Рекомендуем обратиться к кардиологу в ближайшее время. \
            Если чувствуете боль в груди, одышку или головокружение — вызовите скорую.
            """

        case .normal:
            return """
            🟢 Сердечный ритм в норме: \(Int(avgBPM)) BPM, ритм регулярный. \
            Если вы чувствуете тревогу — это может быть субъективное ощущение. \
            Попробуйте дыхательную технику для расслабления.
            """

        case .inconclusive:
            return """
            ⚪ Недостаточно данных для точного анализа. \
            Продолжайте мониторинг. Если симптомы усиливаются — обратитесь к врачу.
            """
        }
    }
}
