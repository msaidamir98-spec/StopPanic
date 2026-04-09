import Combine
import Foundation

/// Предсказание панических атак по паттернам дневника
@MainActor
final class PanicPredictionService: ObservableObject {
    struct DayRisk: Identifiable {
        let id = UUID()
        let dayOfWeek: String
        let riskScore: Double
        let episodeCount: Int
    }

    @Published
    var currentRisk: PanicPrediction?
    @Published
    var weeklyPattern: [DayRisk] = []

    func analyzePatterns(episodes: [DiaryEpisode]) {
        guard !episodes.isEmpty else {
            currentRisk = PanicPrediction(
                id: UUID(), timestamp: Date(), riskLevel: .low,
                confidence: 0.3, triggers: [],
                recommendation: "Ведите дневник для более точного анализа"
            )
            return
        }

        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let recent = episodes.filter { $0.date >= weekAgo }
        let avgIntensity = recent.isEmpty ? 0 : recent.map(\.intensity).reduce(0, +) / recent.count

        // Паттерн по дням
        let dayCounts = Dictionary(grouping: episodes) {
            calendar.component(.weekday, from: $0.date)
        }
        let dayNames = ["", "Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
        let maxCount = dayCounts.values.map(\.count).max() ?? 1

        weeklyPattern = (1 ... 7).map { day in
            let count = dayCounts[day]?.count ?? 0
            return DayRisk(
                dayOfWeek: dayNames[day],
                riskScore: Double(count) / Double(max(maxCount, 1)),
                episodeCount: count
            )
        }

        // Уровень риска
        let (level, conf, rec): (PanicPrediction.RiskLevel, Double, String)
        if recent.count >= 5 && avgIntensity >= 7 {
            (level, conf, rec) = (
                .critical, 0.85,
                "⚠️ Высокая активность. Обратитесь к специалисту."
            )
        } else if recent.count >= 3 || avgIntensity >= 6 {
            (level, conf, rec) = (
                .high, 0.7,
                "Повышенная тревожность. Попробуйте дыхание 4-7-8."
            )
        } else if recent.count >= 1 {
            (level, conf, rec) = (
                .moderate, 0.6,
                "Умеренный уровень. Продолжайте практики."
            )
        } else {
            (level, conf, rec) = (
                .low, 0.5,
                "Отличная неделя! 🎉"
            )
        }

        // Триггеры из заметок
        let allNotes = episodes.suffix(20).map(\.notes).joined(separator: " ").lowercased()
        let triggerMap = [
            "работа": "Стресс", "сон": "Недосып", "кофе": "Кофеин",
            "метро": "Транспорт", "толпа": "Агорафобия", "ночь": "Ночь",
        ]
        let triggers = triggerMap.compactMap { allNotes.contains($0.key) ? $0.value : nil }

        currentRisk = PanicPrediction(
            id: UUID(), timestamp: Date(), riskLevel: level,
            confidence: conf, triggers: triggers, recommendation: rec
        )
    }
}
