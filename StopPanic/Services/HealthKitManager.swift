import Combine
import Foundation
import HealthKit

/// Менеджер HealthKit — чтение пульса с Apple Watch
@MainActor
final class HealthKitManager: ObservableObject {
    // MARK: Internal

    @Published
    var heartRate: Double = 0
    @Published
    var isAuthorized: Bool = false

    func requestPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        // Guard: crash if Info.plist is missing the usage description key
        guard Bundle.main.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") != nil else {
            print("[HealthKitManager] NSHealthShareUsageDescription missing from Info.plist — skipping authorization")
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        ]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] ok, _ in
            let manager = self
            Task { @MainActor in
                manager?.isAuthorized = ok
                if ok { manager?.startObservingHeartRate() }
            }
        }
    }

    // MARK: Private

    private let healthStore = HKHealthStore()

    private func startObservingHeartRate() {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, added, _, _, _ in
            let manager = self
            Task { @MainActor in
                manager?.processHR(samples: added ?? [])
            }
        }
        query.updateHandler = { [weak self] _, added, _, _, _ in
            let manager = self
            Task { @MainActor in
                manager?.processHR(samples: added ?? [])
            }
        }
        healthStore.execute(query)
    }

    private func processHR(samples: [HKSample]) {
        guard let last = samples.last as? HKQuantitySample else { return }
        let bpm = last.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        Task { @MainActor in
            self.heartRate = bpm
        }
    }
}
