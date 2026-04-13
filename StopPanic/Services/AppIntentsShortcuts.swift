import AppIntents

// MARK: - SOSIntent

// Позволяет пользователю запускать SOS, дыхание и другое через Siri.
// "Привет Siri, я паникую" → запускает SOS Flow.

struct SOSIntent: AppIntent {
    static var title: LocalizedStringResource = "Я паникую — SOS"
    static var description = IntentDescription("Запускает экстренную помощь при панической атаке")
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
    static var title: LocalizedStringResource = "Начать дыхание 4-7-8"
    static var description = IntentDescription("Запускает дыхательную сессию 4-7-8 для успокоения")
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
    static var title: LocalizedStringResource = "Проверить уровень тревоги"
    static var description = IntentDescription("Показывает текущий прогноз уровня тревоги")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: "Откройте приложение для просмотра прогноза")
    }
}

// MARK: - QuickLogPanicIntent

struct QuickLogPanicIntent: AppIntent {
    static var title: LocalizedStringResource = "Записать паническую атаку"
    static var description = IntentDescription(
        "Быстро записывает эпизод панической атаки в дневник"
    )
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Сила (1-10)")
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
                "Я паникую в \(.applicationName)",
                "SOS в \(.applicationName)",
                "Помоги мне \(.applicationName)",
                "Паническая атака \(.applicationName)",
                "Мне плохо \(.applicationName)",
            ],
            shortTitle: "SOS Паника",
            systemImageName: "hand.raised.fill"
        )

        AppShortcut(
            intent: StartBreathingIntent(),
            phrases: [
                "Дыши со мной в \(.applicationName)",
                "Начни дыхание в \(.applicationName)",
                "Дыхание 4-7-8 в \(.applicationName)",
            ],
            shortTitle: "Дыхание 4-7-8",
            systemImageName: "wind"
        )

        AppShortcut(
            intent: QuickLogPanicIntent(),
            phrases: [
                "Запиши паническую атаку в \(.applicationName)",
                "Запись в дневник \(.applicationName)",
            ],
            shortTitle: "Записать эпизод",
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
