import Foundation
import os.log
import WatchConnectivity

private let watchLog = Logger(subsystem: "MSK-PRODUKT.StopPanic.watchkitapp", category: "WatchConnectivity")

// MARK: - WatchConnectionManager

// Обмен данными Apple Watch ↔ iPhone:
//  • SOS триггер → iPhone (sendMessage; при недоступности — transferUserInfo с гарантированной доставкой)
//  • Запрос экрана кризисной линии на iPhone ("showCrisisLine")
//  • Уведомление о завершении дыхательной сессии → iPhone
//  • Приём userName (applicationContext) и sosContacts с iPhone —
//    сохраняются, но в watch-UI пока не отображаются (v1.1)

@MainActor
final class WatchConnectionManager: NSObject, ObservableObject {
    // MARK: Lifecycle

    override init() {
        super.init()
        watchLog.info("⌚ WatchConnectionManager init — WCSession.isSupported: \(WCSession.isSupported())")
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            watchLog.info("⌚ WCSession activating...")
        }
    }

    // MARK: Internal

    /// Статус доставки SOS на iPhone
    enum SOSDeliveryStatus {
        /// iPhone доступен — сообщение отправлено напрямую
        case delivered
        /// iPhone недоступен — поставлено в очередь transferUserInfo,
        /// доставится когда iPhone станет доступен
        case queued
    }

    static let shared = WatchConnectionManager()

    @Published
    var isPhoneReachable = false
    @Published
    var userName: String = "" // unused: kept for v1.1 (приходит через applicationContext)
    @Published
    var sosContacts: [(name: String, phone: String)] = [] // unused: kept for v1.1

    // MARK: - Send to iPhone

    /// Отправить SOS-сигнал на iPhone.
    /// - Returns: `.delivered` если iPhone доступен и сообщение отправлено напрямую,
    ///   `.queued` если SOS поставлен в очередь гарантированной доставки.
    @discardableResult
    func triggerSOSOnPhone() -> SOSDeliveryStatus {
        let payload: [String: Any] = ["type": "sos", "timestamp": Date().timeIntervalSince1970]
        watchLog.critical("🚨⌚ SOS TRIGGERED! Sending to iPhone. Reachable: \(self.session?.isReachable ?? false)")

        guard let session else {
            watchLog.error("❌⌚ WCSession unsupported — SOS cannot be sent")
            return .queued
        }

        guard session.isReachable else {
            watchLog.error("❌⌚ iPhone NOT reachable — queueing SOS via transferUserInfo")
            session.transferUserInfo(payload)
            return .queued
        }

        session.sendMessage(
            payload,
            replyHandler: { reply in
                watchLog.info("✅⌚ iPhone confirmed SOS receipt: \(reply)")
            },
            errorHandler: { [weak session] error in
                watchLog.error("❌⌚ SOS send failed: \(error.localizedDescription) — falling back to transferUserInfo")
                session?.transferUserInfo(payload)
            }
        )
        return .delivered
    }

    /// Попросить iPhone показать экран кризисной линии (по аналогии с SOS).
    /// На UI часов не влияет — основная информация показывается локально.
    func requestCrisisLineOnPhone() {
        watchLog.info("📞⌚ Requesting crisis line screen on iPhone. Reachable: \(self.session?.isReachable ?? false)")
        guard let session, session.isReachable else {
            watchLog.warning("⚠️⌚ iPhone not reachable — crisis line request skipped")
            return
        }
        session.sendMessage(
            ["type": "showCrisisLine"],
            replyHandler: nil,
            errorHandler: { error in
                watchLog.error("❌⌚ Crisis line request failed: \(error.localizedDescription)")
            }
        )
    }

    /// Сообщить о завершении сессии
    func notifySessionCompleted() {
        watchLog.info("✅⌚ Breathing session completed — notifying iPhone")
        guard let session, session.isReachable else {
            watchLog.warning("⚠️⌚ iPhone not reachable for session notification")
            return
        }
        session.sendMessage(
            ["type": "sessionCompleted"],
            replyHandler: nil
        )
    }

    // MARK: Private

    private var session: WCSession?
}

// MARK: WCSessionDelegate

extension WatchConnectionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        watchLog
            .info(
                "⌚ WCSession activated: state=\(activationState.rawValue) reachable=\(session.isReachable) error=\(error?.localizedDescription ?? "none")"
            )
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        watchLog.info("⌚ Reachability changed: \(session.isReachable ? "📱 CONNECTED" : "❌ DISCONNECTED")")
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
        }
    }

    /// Получение сообщений от iPhone
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handlePhoneMessage(message)
        }
    }

    /// Получение контекста от iPhone
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            if let name = applicationContext["userName"] as? String {
                self.userName = name
            }
        }
    }

    @MainActor
    private func handlePhoneMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "sosContacts":
            if let contacts = message["contacts"] as? [[String: String]] {
                sosContacts = contacts.compactMap { dict in
                    guard let name = dict["name"], let phone = dict["phone"] else { return nil }
                    return (name: name, phone: phone)
                }
            }
        default:
            break
        }
    }
}
