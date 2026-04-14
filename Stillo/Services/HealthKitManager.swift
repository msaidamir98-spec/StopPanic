import Combine
import Foundation
import HealthKit
import UserNotifications

/// Менеджер HealthKit — пульс с Apple Watch + фоновые уведомления о тревоге
@MainActor
final class HealthKitManager: ObservableObject {
    // MARK: Internal

    @Published var heartRate: Double = 0
    @Published var isAuthorized: Bool = false
    @Published var isElevatedHR: Bool = false
    @Published var authorizationDenied: Bool = false

    /// Порог ЧСС для уведомления о тревоге (покой)
    let elevatedHRThreshold: Double = 100

    func requestPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        guard Bundle.main.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") != nil else {
            print("[HealthKitManager] NSHealthShareUsageDescription missing from Info.plist — skipping authorization")
            return
        }

        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        else { return }

        let readTypes: Set<HKObjectType> = [hrType, hrvType]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] ok, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                // requestAuthorization returns true even if user denied — check actual status
                let status = healthStore.authorizationStatus(for: hrType)
                if ok, status != .sharingDenied {
                    isAuthorized = true
                    authorizationDenied = false
                    startObservingHeartRate()
                    enableBackgroundHeartRateDelivery()
                } else {
                    isAuthorized = false
                    authorizationDenied = true
                }
            }
        }
    }

    // MARK: Private

    private let healthStore = HKHealthStore()
    private var lastHighHRNotification: Date?

    private func startObservingHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, added, _, _, _ in
            Task { @MainActor [weak self] in
                self?.processHR(samples: added ?? [])
            }
        }
        query.updateHandler = { [weak self] _, added, _, _, _ in
            Task { @MainActor [weak self] in
                self?.processHR(samples: added ?? [])
            }
        }
        healthStore.execute(query)
    }

    /// Enable background delivery for heart rate → push notification on high HR
    private func enableBackgroundHeartRateDelivery() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        healthStore.enableBackgroundDelivery(for: hrType, frequency: .immediate) { success, error in
            if let error {
                print("[HealthKit] Background delivery error: \(error)")
            } else if success {
                print("[HealthKit] Background heart rate delivery enabled")
            }
        }

        // Background observer query
        let observerQuery = HKObserverQuery(sampleType: hrType, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }

            // Fetch latest sample
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let sampleQuery = HKSampleQuery(
                sampleType: hrType,
                predicate: HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-300), end: nil, options: .strictStartDate),
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    completionHandler()
                    return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    heartRate = bpm
                    if bpm >= elevatedHRThreshold {
                        isElevatedHR = true
                        sendHighHeartRateNotification(bpm: bpm)
                    } else {
                        isElevatedHR = false
                    }
                }
                completionHandler()
            }
            self?.healthStore.execute(sampleQuery)
        }
        healthStore.execute(observerQuery)
    }

    private func processHR(samples: [HKSample]) {
        guard let last = samples.last as? HKQuantitySample else { return }
        let bpm = last.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        heartRate = bpm
        if bpm >= elevatedHRThreshold {
            isElevatedHR = true
            sendHighHeartRateNotification(bpm: bpm)
        } else {
            isElevatedHR = false
        }
    }

    /// Send local push if HR is elevated (throttled to once per 30 min)
    private func sendHighHeartRateNotification(bpm: Double) {
        // Throttle: max once per 30 minutes
        if let last = lastHighHRNotification, Date().timeIntervalSince(last) < 1_800 {
            return
        }
        lastHighHRNotification = Date()

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_hr_high_title")
        content.body = String(localized: "notif_hr_high_body \(Int(bpm))")
        content.sound = .default
        content.categoryIdentifier = "HIGH_HR_ALERT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "high_hr_\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
