// MARK: - Localization Strings

// Двуязычная поддержка: Русский (основной) + English.
// Все строки централизованы для лёгкого перевода.

import Foundation

enum L10n {
    // MARK: - General

    enum General {
        static let appName = String(localized: "app.name", defaultValue: "Stillō")
        static let done = String(localized: "general.done", defaultValue: "Готово")
        static let cancel = String(localized: "general.cancel", defaultValue: "Отмена")
        static let save = String(localized: "general.save", defaultValue: "Сохранить")
        static let next = String(localized: "general.next", defaultValue: "Далее →")
        static let skip = String(localized: "general.skip", defaultValue: "Пропустить")
        static let start = String(localized: "general.start", defaultValue: "Начать")
        static let stop = String(localized: "general.stop", defaultValue: "Остановить")
        static let close = String(localized: "general.close", defaultValue: "Закрыть")
        static let important = String(localized: "general.important", defaultValue: "Важно")
    }

    // MARK: - Tabs

    enum Tabs {
        static let home = String(localized: "tabs.home", defaultValue: "Главная")
        static let tools = String(localized: "tabs.tools", defaultValue: "Инструменты")
        static let heart = String(localized: "tabs.heart", defaultValue: "Сердце")
        static let journal = String(localized: "tabs.journal", defaultValue: "Дневник")
        static let profile = String(localized: "tabs.profile", defaultValue: "Профиль")
    }

    // MARK: - Home

    enum Home {
        static let sosButton = String(localized: "home.sos.button", defaultValue: "SOS")
        static let sosSubtitle = String(localized: "home.sos.subtitle", defaultValue: "Нажми, если паника")
        static let quickActions = String(localized: "home.quickActions", defaultValue: "Быстрые действия")
        static let breathe = String(localized: "home.breathe", defaultValue: "Дыхание")
        static let grounding = String(localized: "home.grounding", defaultValue: "Заземление")
        static let heartCheck = String(localized: "home.heartCheck", defaultValue: "Пульс")
    }

    // MARK: - SOS

    enum SOS {
        static let title = String(localized: "sos.title", defaultValue: "SOS — Я в панике")
        static let stepByStep = String(localized: "sos.stepByStep", defaultValue: "Пошаговая помощь прямо сейчас")
        static let breatheIn = String(localized: "sos.breatheIn", defaultValue: "Вдох")
        static let hold = String(localized: "sos.hold", defaultValue: "Задержка")
        static let breatheOut = String(localized: "sos.breatheOut", defaultValue: "Выдох")
        static let youAreSafe = String(localized: "sos.youAreSafe", defaultValue: "Ты в безопасности")
        static let panicWillPass = String(localized: "sos.panicWillPass", defaultValue: "Тревога пройдёт. Это временно.")
    }

    // MARK: - Breathing

    enum Breathing {
        static let ready = String(localized: "breathing.ready", defaultValue: "Готов?")
        static let inhale = String(localized: "breathing.inhale", defaultValue: "Вдох")
        static let holdBreath = String(localized: "breathing.hold", defaultValue: "Задержка")
        static let exhale = String(localized: "breathing.exhale", defaultValue: "Выдох")
        static let pause = String(localized: "breathing.pause", defaultValue: "Пауза")
        static let complete = String(localized: "breathing.complete", defaultValue: "Готово!")
        static let excellent = String(localized: "breathing.excellent", defaultValue: "Отлично! 🎉")
        static let cycles = String(localized: "breathing.cycles", defaultValue: "циклов")
        static let time = String(localized: "breathing.time", defaultValue: "время")
        static let throughNose = String(localized: "breathing.throughNose", defaultValue: "через нос 🫁")
        static let calmly = String(localized: "breathing.calmly", defaultValue: "спокойно 🧘")
        static let throughMouth = String(localized: "breathing.throughMouth", defaultValue: "через рот 💨")
        static let relax = String(localized: "breathing.relax", defaultValue: "расслабься")
    }

    // MARK: - Journal

    enum Journal {
        static let title = String(localized: "journal.title", defaultValue: "Дневник")
        static let entries = String(localized: "journal.entries", defaultValue: "записей")
        static let episodes = String(localized: "journal.episodes", defaultValue: "Эпизоды")
        static let mood = String(localized: "journal.mood", defaultValue: "Настроение")
        static let insights = String(localized: "journal.insights", defaultValue: "Инсайты")
        static let emptyTitle = String(localized: "journal.empty.title", defaultValue: "Дневник пока пуст")
        static let emptySubtitle = String(localized: "journal.empty.subtitle", defaultValue: "Записывай эпизоды, чтобы увидеть паттерны")
        static let perWeek = String(localized: "journal.perWeek", defaultValue: "за неделю")
        static let avgIntensity = String(localized: "journal.avgIntensity", defaultValue: "средняя сила")
        static let trend = String(localized: "journal.trend", defaultValue: "тренд")
    }

    // MARK: - Profile

    enum Profile {
        static let member = String(localized: "profile.member", defaultValue: "Участник Stillō")
        static let setName = String(localized: "profile.setName", defaultValue: "Укажи имя")
        static let entries = String(localized: "profile.entries", defaultValue: "Записей")
        static let sessions = String(localized: "profile.sessions", defaultValue: "Сессий")
        static let breathingMin = String(localized: "profile.breathingMin", defaultValue: "мин")
        static let awards = String(localized: "profile.awards", defaultValue: "Наград")
        static let sosContacts = String(localized: "profile.sosContacts", defaultValue: "SOS Контакты")
        static let settings = String(localized: "profile.settings", defaultValue: "Настройки")
        static let notifications = String(localized: "profile.notifications", defaultValue: "Уведомления")
        static let crisisLine = String(localized: "profile.crisisLine", defaultValue: "Телефон доверия")
    }

    // MARK: - Onboarding

    enum Onboarding {
        static let tagline = String(localized: "onboarding.tagline", defaultValue: "Точка покоя\nв моменте тревоги")
        static let whatsYourName = String(localized: "onboarding.name", defaultValue: "Как тебя зовут?")
        static let howOften = String(localized: "onboarding.howOften", defaultValue: "Как часто ты испытываешь\nпанические атаки?")
        static let whatGoals = String(localized: "onboarding.whatGoals", defaultValue: "Чего ты хочешь достичь?")
        static let allReady = String(localized: "onboarding.allReady", defaultValue: "Всё готово")
        static let startUsing = String(localized: "onboarding.startUsing", defaultValue: "Начать использовать")
        static let notAlone = String(localized: "onboarding.notAlone", defaultValue: "Ты больше не один.")
        static let medicalDisclaimer = String(
            localized: "onboarding.disclaimer",
            defaultValue: "Stillō — помощник, НЕ замена врачу. При подозрении на сердечную проблему всегда вызывайте скорую."
        )
    }

    // MARK: - Greetings

    static func greeting(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting = switch hour {
        case 5 ..< 12:
            String(localized: "greeting.morning", defaultValue: "Доброе утро")
        case 12 ..< 17:
            String(localized: "greeting.afternoon", defaultValue: "Добрый день")
        case 17 ..< 22:
            String(localized: "greeting.evening", defaultValue: "Добрый вечер")
        default:
            String(localized: "greeting.night", defaultValue: "Спокойной ночи")
        }

        if name.isEmpty {
            return timeGreeting
        }
        return "\(timeGreeting), \(name)"
    }
}
