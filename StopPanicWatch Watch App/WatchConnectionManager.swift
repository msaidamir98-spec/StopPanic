import Foundation
import WatchConnectivity
import os.log

private let watchLog = Logger(subsystem: "MSK-PRODUKT.StopPanic.watchkitapp", category: "WatchConnectivity")

// MARK: - Watch Connectivity Manager (watchOS Side)
// Обмен данными Apple Watch ↔ iPhone:
//  • SOS триггер → iPhone
//  • Пульс → iPhone
//  • Получение контактов/настроек с iPhone

@MainActor
final class WatchConnectionManager: NSObject, ObservableObject {
    
    static let shared = WatchConnectionManager()
    
    @Published var isPhoneReachable = false
    @Published var userName: String = ""
    @Published var sosContacts: [(name: String, phone: String)] = []
    
    private var session: WCSession?
    
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
    
    // MARK: - Send to iPhone
    
    /// Отправить SOS-сигнал на iPhone
    func triggerSOSOnPhone() {
        watchLog.critical("🚨⌚ SOS TRIGGERED! Sending to iPhone. Reachable: \(self.session?.isReachable ?? false)")
        guard let session, session.isReachable else {
            watchLog.error("❌⌚ iPhone NOT reachable — SOS cannot be sent")
            return
        }
        session.sendMessage(
            ["type": "sos", "timestamp": Date().timeIntervalSince1970],
            replyHandler: { reply in
                watchLog.info("✅⌚ iPhone confirmed SOS receipt: \(reply)")
            },
            errorHandler: { error in
                watchLog.error("❌⌚ SOS send failed: \(error.localizedDescription)")
            }
        )
    }
    
    /// Отправить текущий пульс на iPhone
    func sendHeartRate(_ bpm: Double) {
        guard let session, session.isReachable else { return }
        watchLog.info("💓⌚ Sending HR \(bpm) to iPhone")
        session.sendMessage(
            ["type": "heartRate", "bpm": bpm],
            replyHandler: nil
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
}

// MARK: - WCSessionDelegate

extension WatchConnectionManager: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        watchLog.info("⌚ WCSession activated: state=\(activationState.rawValue) reachable=\(session.isReachable) error=\(error?.localizedDescription ?? "none")")
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
