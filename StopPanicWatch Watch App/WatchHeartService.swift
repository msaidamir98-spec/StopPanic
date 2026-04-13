import Foundation
import SwiftUI
import HealthKit
import Combine

/// Сервис мониторинга пульса на Apple Watch
/// Анализирует ЧСС в реальном времени и определяет ПА vs Инфаркт
@MainActor
class WatchHeartService: ObservableObject {
    
    // MARK: - Published
    @Published var currentHR: Double = 0
    @Published var hrvValue: Double = 0
    @Published var irregularity: Double = 0
    @Published var isMonitoring = false
    @Published var suggestMedicalConsult = false
    
    // MARK: - Diagnosis
    enum DiagnosisResult {
        case normal
        case panicAttack
        case possibleCardiac
        case inconclusive
    }
    
    @Published var diagnosis: DiagnosisResult = .normal
    
    struct HeartStatus {
        let text: String
        let color: SwiftUI.Color
    }
    
    var currentStatus: HeartStatus {
        switch diagnosis {
        case .normal:
            return HeartStatus(text: String(localized: "watch.status_normal"), color: .green)
        case .panicAttack:
            return HeartStatus(text: String(localized: "watch.status_panic"), color: .yellow)
        case .possibleCardiac:
            return HeartStatus(text: String(localized: "watch.status_cardiac"), color: .red)
        case .inconclusive:
            return HeartStatus(text: String(localized: "watch.status_analyzing"), color: .orange)
        }
    }
    
    var diagnosisIcon: String {
        switch diagnosis {
        case .normal: return "checkmark.heart.fill"
        case .panicAttack: return "brain.head.profile"
        case .possibleCardiac: return "heart.slash.fill"
        case .inconclusive: return "questionmark.circle"
        }
    }
    
    var diagnosisColor: SwiftUI.Color {
        currentStatus.color
    }
    
    var diagnosisTitle: String {
        switch diagnosis {
        case .normal:
            return String(localized: "watch.diag_normal_title")
        case .panicAttack:
            return String(localized: "watch.diag_panic_title")
        case .possibleCardiac:
            return String(localized: "watch.diag_cardiac_title")
        case .inconclusive:
            return String(localized: "watch.diag_inconclusive_title")
        }
    }
    
    var diagnosisDetail: String {
        switch diagnosis {
        case .normal:
            return String(localized: "watch.diag_normal_detail")
        case .panicAttack:
            return String(localized: "watch.diag_panic_detail")
        case .possibleCardiac:
            return String(localized: "watch.diag_cardiac_detail")
        case .inconclusive:
            return String(localized: "watch.diag_inconclusive_detail")
        }
    }
    
    // MARK: - Private
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var sampleBuffer: [(bpm: Double, time: Date)] = []
    
    // Пороговые значения
    private let dangerousHR: Double = 150
    private let panicMinHR: Double = 90
    private let irregularityThreshold: Double = 0.35
    private let lowHRV: Double = 20
    
    // MARK: - Start / Stop
    
    func startMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        healthStore.requestAuthorization(toShare: nil, read: [hrType, hrvType]) { [weak self] ok, _ in
            guard ok, let self else { return }
            Task { @MainActor in
                self.startLiveQuery()
            }
        }
    }
    
    func stopMonitoring() {
        if let q = anchoredQuery {
            healthStore.stop(q)
        }
        anchoredQuery = nil
        isMonitoring = false
        sampleBuffer.removeAll()
    }
    
    // MARK: - Live Query
    
    private func startLiveQuery() {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(
            withStart: Date(), end: nil, options: .strictStartDate
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
                self.processHRSamples(samples)
            }
        }
        
        query.updateHandler = { [weak self] _, added, _, _, _ in
            guard let self else { return }
            let samples = added ?? []
            Task { @MainActor in
                self.processHRSamples(samples)
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
    
    // MARK: - Differential Analysis
    
    private func analyzePattern() {
        let bpms = sampleBuffer.map(\.bpm)
        let avgHR = bpms.reduce(0, +) / Double(bpms.count)
        
        // Рассчитать нерегулярность (RMSSD из RR-интервалов)
        let rrIntervals = bpms.map { 60.0 / $0 }
        var diffSquareSum: Double = 0
        for i in 1..<rrIntervals.count {
            let diff = rrIntervals[i] - rrIntervals[i-1]
            diffSquareSum += diff * diff
        }
        let rmssd = sqrt(diffSquareSum / Double(max(rrIntervals.count - 1, 1)))
        irregularity = min(rmssd / 0.2, 1.0) // Нормализация
        
        // HRV (стандартное отклонение RR)
        let meanRR = rrIntervals.reduce(0, +) / Double(rrIntervals.count)
        let variance = rrIntervals.map { ($0 - meanRR) * ($0 - meanRR) }.reduce(0, +) / Double(rrIntervals.count)
        hrvValue = sqrt(variance) * 1000 // мс
        
        // Классификация
        if avgHR < panicMinHR && irregularity < irregularityThreshold {
            // Нормальный пульс, ровный ритм
            diagnosis = .normal
            suggestMedicalConsult = false
        } else if irregularity >= irregularityThreshold && avgHR >= dangerousHR {
            // Нерегулярный + высокий → возможно сердце
            diagnosis = .possibleCardiac
            suggestMedicalConsult = true
        } else if irregularity >= irregularityThreshold {
            // Нерегулярный но не критичный
            diagnosis = .possibleCardiac
            suggestMedicalConsult = false
        } else if avgHR >= panicMinHR && irregularity < irregularityThreshold {
            // Повышенный но ровный → ПА
            diagnosis = .panicAttack
            suggestMedicalConsult = false
        } else {
            diagnosis = .inconclusive
            suggestMedicalConsult = false
        }
    }
}
