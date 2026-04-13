import AppIntents

// MARK: - SOSIntent

// Allows users to trigger SOS, breathing, and more via Siri.
// "Hey Siri, I'm panicking" → triggers SOS Flow.

struct SOSIntent: AppIntent {
    static var title: LocalizedStringResource = "I'm panicking — SOS"
    static var description = IntentDescription("Activates emergency help during a panic attack")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .triggerSOSFromIntent, object: nil)
        }
        return .result()
    }
}

// MARK: - StartBreathingIntent

struct StartBreathingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start 4-7-8 Breathing"
    static var description = IntentDescription("Starts a calming 4-7-8 breathing session")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .triggerBreathingFromIntent, object: nil)
        }
        return .result()
    }
}

// MARK: - CheckAnxietyStatusIntent

struct CheckAnxietyStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check anxiety level"
    static var description = IntentDescription("Shows the current anxiety forecast")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: String(localized: "intent.open_forecast"))
    }
}

// MARK: - QuickLogPanicIntent

struct QuickLogPanicIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a panic attack"
    static var description = IntentDescription(
        "Quickly logs a panic episode in the diary"
    )
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Intensity (1-10)")
    var intensity: Int?

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            let level = intensity ?? 5
            NotificationCenter.default.post(
                name: .triggerQuickLogFromIntent,
                object: nil,
                userInfo: ["intensity": level]
            )
        }
        return .result()
    }
}

// MARK: - StilloShortcuts

struct StilloShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SOSIntent(),
            phrases: [
                "I'm panicking in \(.applicationName)",
                "SOS in \(.applicationName)",
                "Help me \(.applicationName)",
                "Panic attack \(.applicationName)",
                "I feel bad \(.applicationName)",
                "Я паникую в \(.applicationName)",
                "Помоги мне \(.applicationName)",
                "Мне плохо \(.applicationName)",
            ],
            shortTitle: "SOS Panic",
            systemImageName: "hand.raised.fill"
        )

        AppShortcut(
            intent: StartBreathingIntent(),
            phrases: [
                "Breathe with me in \(.applicationName)",
                "Start breathing in \(.applicationName)",
                "4-7-8 breathing in \(.applicationName)",
                "Дыши со мной в \(.applicationName)",
                "Дыхание в \(.applicationName)",
            ],
            shortTitle: "4-7-8 Breathing",
            systemImageName: "wind"
        )

        AppShortcut(
            intent: QuickLogPanicIntent(),
            phrases: [
                "Log a panic attack in \(.applicationName)",
                "Diary entry in \(.applicationName)",
                "Записать приступ в \(.applicationName)",
                "Запись в дневник \(.applicationName)",
            ],
            shortTitle: "Log Episode",
            systemImageName: "pencil.circle.fill"
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let triggerSOSFromIntent = Notification.Name("triggerSOSFromIntent")
    static let triggerBreathingFromIntent = Notification.Name("triggerBreathingFromIntent")
    static let triggerQuickLogFromIntent = Notification.Name("triggerQuickLogFromIntent")
}
