import Combine
import Foundation
import os.log
import WatchConnectivity

// MARK: - WatchConnectivityService

// Обмен данными iPhone ↔ Apple Watch:
//  • SOS триггер с часов → iPhone
//  • Пульс с часов → iPhone
//  • Настройки/контакты → часы
//  • Статус сессий → часы

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    // MARK: Lifecycle

    override init() {
        super.init()
        Self.log.info(
            "📱 WatchConnectivityService init — WCSession.isSupported: \(WCSession.isSupported())"
        )
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            Self.log.info("📱 WCSession activating...")
        }
    }

    // MARK: Internal

    static let shared = WatchConnectivityService()

    @Published
    var isWatchReachable = false
    @Published
    var lastWatchHeartRate: Double = 0
    @Published
    var watchSOSTriggered = false

    // MARK: - Send to Watch

    /// Отправить SOS-контакты на часы
    func sendSOSContacts(_ contacts: [(name: String, phone: String)]) {
        guard let session, session.isReachable else { return }
        let data: [[String: String]] = contacts.map { ["name": $0.name, "phone": $0.phone] }
        session.sendMessage(["type": "sosContacts", "contacts": data], replyHandler: nil)
    }

    /// Отправить настройки пользователя на часы
    func syncUserSettings(userName: String, breathingMinutes: Int, sessionsCompleted: Int) {
        guard let session, session.activationState == .activated else { return }
        let context: [String: Any] = [
            "userName": userName,
            "breathingMinutes": breathingMinutes,
            "sessionsCompleted": sessionsCompleted,
        ]
        try? session.updateApplicationContext(context)
    }

    /// Отправить сообщение на часы
    func sendMessage(_ message: [String: Any]) {
        guard let session, session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil)
    }

    // MARK: Private

    nonisolated private static let log = Logger(
        subsystem: "MSK-PRODUKT.StopPanic", category: "WatchConnectivity"
    )

    private var session: WCSession?
}

// MARK: WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Self.log.info(
            "📱 WCSession activated: state=\(activationState.rawValue) paired=\(session.isPaired) reachable=\(session.isReachable) error=\(error?.localizedDescription ?? "none")"
        )
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Self.log.info("📱 WCSession became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Self.log.info("📱 WCSession deactivated — reactivating")
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Self.log.info(
            "📱 Watch reachability: \(session.isReachable ? "⌚ CONNECTED" : "❌ DISCONNECTED")"
        )
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    /// Получение сообщений с часов
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handleWatchMessage(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            handleWatchMessage(message)
            replyHandler(["status": "ok"])
        }
    }

    @MainActor
    private func handleWatchMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        Self.log.info("📱 Received message from Watch: type=\(type)")

        switch type {
        case "sos":
            Self.log.critical("🚨📱 SOS RECEIVED FROM WATCH! Triggering emergency flow...")
            watchSOSTriggered = true
            NotificationCenter.default.post(name: .triggerSOSFromIntent, object: nil)
            Self.log.critical("🚨📱 SOS notification posted — UI should show SOS overlay")

        case "heartRate":
            if let hr = message["bpm"] as? Double {
                Self.log.info("💓📱 Watch heart rate: \(hr) BPM")
                lastWatchHeartRate = hr
            }

        case "sessionCompleted":
            Self.log.info("✅📱 Watch breathing session completed!")
            NotificationCenter.default.post(
                name: NSNotification.Name("watchSessionCompleted"), object: nil
            )

        default:
            Self.log.warning("⚠️📱 Unknown message type: \(type)")
        }
    }
}
