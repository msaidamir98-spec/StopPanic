import Combine
import Foundation
import HealthKit
import os.log
import SwiftUI

private let heartLog = Logger(subsystem: "MSK-PRODUKT.StopPanic.watchkitapp", category: "WatchHeart")

/// Сервис мониторинга пульса на Apple Watch
/// Мониторинг ЧСС в реальном времени — анализ паттернов пульса (wellness)
@MainActor
class WatchHeartService: ObservableObject {
    // MARK: Internal

    // MARK: - Pattern Analysis

    enum DiagnosisResult {
        case normal
        case stressResponse
        case irregularPattern
        case inconclusive
    }

    struct HeartStatus {
        let text: String
        let color: SwiftUI.Color
    }

    // MARK: - Published

    @Published
    var currentHR: Double = 0
    @Published
    var hrvValue: Double = 0
    @Published
    var irregularity: Double = 0
    @Published
    var isMonitoring = false
    @Published
    var suggestMedicalConsult = false
    /// HealthKit-авторизация отклонена / не получена — UI может показать empty-state
    @Published
    var authorizationDenied = false

    @Published
    var diagnosis: DiagnosisResult = .normal

    var currentStatus: HeartStatus {
        switch diagnosis {
        case .normal:
            HeartStatus(text: String(localized: "watch.status_normal"), color: .green)
        case .stressResponse:
            HeartStatus(text: String(localized: "watch.status_stress"), color: .yellow)
        case .irregularPattern:
            HeartStatus(text: String(localized: "watch.status_irregular"), color: .red)
        case .inconclusive:
            HeartStatus(text: String(localized: "watch.status_analyzing"), color: .orange)
        }
    }

    var diagnosisIcon: String {
        switch diagnosis {
        case .normal: "checkmark.heart.fill"
        case .stressResponse: "brain.head.profile"
        case .irregularPattern: "exclamationmark.heart.fill"
        case .inconclusive: "questionmark.circle"
        }
    }

    var diagnosisColor: SwiftUI.Color {
        currentStatus.color
    }

    var diagnosisTitle: String {
        switch diagnosis {
        case .normal:
            String(localized: "watch.diag_normal_title")
        case .stressResponse:
            String(localized: "watch.diag_stress_title")
        case .irregularPattern:
            String(localized: "watch.diag_irregular_title")
        case .inconclusive:
            String(localized: "watch.diag_inconclusive_title")
        }
    }

    var diagnosisDetail: String {
        switch diagnosis {
        case .normal:
            String(localized: "watch.diag_normal_detail")
        case .stressResponse:
            String(localized: "watch.diag_stress_detail")
        case .irregularPattern:
            String(localized: "watch.diag_irregular_detail")
        case .inconclusive:
            String(localized: "watch.diag_inconclusive_detail")
        }
    }

    // MARK: - Start / Stop

    func startMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        else { return }

        healthStore.requestAuthorization(toShare: nil, read: [hrType, hrvType]) { [weak self] ok, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    heartLog.error("⌚ HealthKit authorization error: \(error.localizedDescription)")
                }
                guard ok else {
                    heartLog.error("⌚ HealthKit authorization denied — monitoring unavailable")
                    self.authorizationDenied = true
                    return
                }
                self.authorizationDenied = false
                self.startWorkoutSession()
                self.startLiveQuery()
            }
        }
    }

    func stopMonitoring() {
        if let q = anchoredQuery {
            healthStore.stop(q)
        }
        anchoredQuery = nil
        workoutSession?.end()
        workoutSession = nil
        isMonitoring = false
        sampleBuffer.removeAll()
    }

    // MARK: Private

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var sampleBuffer: [(bpm: Double, time: Date)] = []

    // Пороговые значения (wellness)
    private let elevatedHR: Double = 150
    private let stressMinHR: Double = 90
    private let irregularityThreshold: Double = 0.35
    private let lowHRV: Double = 20

    // MARK: - Workout Session

    /// Активная workout-сессия (.mindAndBody) заставляет watchOS отдавать
    /// HR-сэмплы каждые несколько секунд вместо раза в минуты
    private func startWorkoutSession() {
        guard workoutSession == nil else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            session.startActivity(with: Date())
            workoutSession = session
            heartLog.info("⌚ Workout session (.mindAndBody) started — live HR enabled")
        } catch {
            heartLog.error("⌚ Failed to start workout session: \(error.localizedDescription) — falling back to passive sampling")
            workoutSession = nil
        }
    }

    // MARK: - Live Query

    private func startLiveQuery() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(), end: nil, options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, added, _, _, error in
            if let error {
                heartLog.error("⌚ HR anchored query failed: \(error.localizedDescription)")
            }
            let samples = added ?? []
            Task { @MainActor [weak self] in
                self?.processHRSamples(samples)
            }
        }

        query.updateHandler = { [weak self] _, added, _, _, error in
            if let error {
                heartLog.error("⌚ HR query update failed: \(error.localizedDescription)")
            }
            let samples = added ?? []
            Task { @MainActor [weak self] in
                self?.processHRSamples(samples)
            }
        }

        healthStore.execute(query)
        anchoredQuery = query
        isMonitoring = true
    }

    // MARK: - Processing

    private func processHRSamples(_ samples: [HKSample]) {
        let unit = HKUnit.count().unitDivided(by: .minute())

        for sample in samples {
            guard let qs = sample as? HKQuantitySample else { continue }
            let bpm = qs.quantity.doubleValue(for: unit)
            sampleBuffer.append((bpm: bpm, time: qs.startDate))
        }

        // Держим последние 60 отсчётов
        if sampleBuffer.count > 60 {
            sampleBuffer = Array(sampleBuffer.suffix(60))
        }

        guard let last = sampleBuffer.last else { return }
        currentHR = last.bpm

        // Анализ при достаточном количестве данных
        if sampleBuffer.count >= 5 {
            analyzePattern()
        } else {
            diagnosis = .inconclusive
        }
    }

    // MARK: - Pattern Analysis

    private func analyzePattern() {
        let bpms = sampleBuffer.map(\.bpm)
        let avgHR = bpms.reduce(0, +) / Double(bpms.count)

        // Рассчитать нерегулярность (RMSSD из RR-интервалов)
        let rrIntervals = bpms.map { 60.0 / max($0, 1) }
        var diffSquareSum: Double = 0
        for i in 1 ..< rrIntervals.count {
            let diff = rrIntervals[i] - rrIntervals[i - 1]
            diffSquareSum += diff * diff
        }
        let rmssd = sqrt(diffSquareSum / Double(max(rrIntervals.count - 1, 1)))
        irregularity = min(rmssd / 0.2, 1.0)

        // HRV (стандартное отклонение RR)
        let meanRR = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
        let variance = rrIntervals.map { ($0 - meanRR) * ($0 - meanRR) }.reduce(0, +) / Double(rrIntervals.count)
        hrvValue = sqrt(variance) * 1_000 // мс

        // Классификация паттернов
        if avgHR < stressMinHR, irregularity < irregularityThreshold {
            diagnosis = .normal
            suggestMedicalConsult = false
        } else if irregularity >= irregularityThreshold, avgHR >= elevatedHR {
            // Нерегулярный + высокий → рекомендация к врачу
            diagnosis = .irregularPattern
            suggestMedicalConsult = true
        } else if irregularity >= irregularityThreshold {
            // Нерегулярный но не критичный
            diagnosis = .irregularPattern
            suggestMedicalConsult = false
        } else if avgHR >= stressMinHR, irregularity < irregularityThreshold {
            // Повышенный но ровный ритм → стрессовая реакция
            diagnosis = .stressResponse
            suggestMedicalConsult = false
        } else {
            diagnosis = .inconclusive
            suggestMedicalConsult = false
        }
    }
}
