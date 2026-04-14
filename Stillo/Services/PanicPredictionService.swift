import Combine
import Foundation

/// Pattern Analysis — анализ паттернов из дневника (честное название, не "AI prediction")
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
                recommendation: String(localized: "pattern_empty")
            )
            return
        }

        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = episodes.filter { $0.date >= weekAgo }
        let avgIntensity = recent.isEmpty ? 0 : recent.map(\.intensity).reduce(0, +) / recent.count

        // Localized day names
        let dayNames = [
            "", String(localized: "day_sun"), String(localized: "day_mon"),
            String(localized: "day_tue"), String(localized: "day_wed"),
            String(localized: "day_thu"), String(localized: "day_fri"),
            String(localized: "day_sat"),
        ]

        let dayCounts = Dictionary(grouping: episodes) {
            calendar.component(.weekday, from: $0.date)
        }
        let maxCount = dayCounts.values.map(\.count).max() ?? 1

        weeklyPattern = (1 ... 7).map { day in
            let count = dayCounts[day]?.count ?? 0
            return DayRisk(
                dayOfWeek: dayNames[day],
                riskScore: Double(count) / Double(max(maxCount, 1)),
                episodeCount: count
            )
        }

        // Risk level — honest heuristic (NOT "AI")
        let (level, conf, rec): (PanicPrediction.RiskLevel, Double, String)
        if recent.count >= 5 && avgIntensity >= 7 {
            (level, conf, rec) = (
                .critical, 0.85,
                String(localized: "pattern_critical")
            )
        } else if recent.count >= 3 || avgIntensity >= 6 {
            (level, conf, rec) = (
                .high, 0.7,
                String(localized: "pattern_high")
            )
        } else if recent.count >= 1 {
            (level, conf, rec) = (
                .moderate, 0.6,
                String(localized: "pattern_moderate")
            )
        } else {
            (level, conf, rec) = (
                .low, 0.5,
                String(localized: "pattern_low")
            )
        }

        // Trigger detection from diary notes — localized
        let allNotes = episodes.suffix(20).map(\.notes).joined(separator: " ").lowercased()
        let triggerMap: [(key: String, value: String)] = [
            ("работа", String(localized: "trigger_stress")),
            ("work", String(localized: "trigger_stress")),
            ("сон", String(localized: "trigger_sleep")),
            ("sleep", String(localized: "trigger_sleep")),
            ("кофе", String(localized: "trigger_caffeine")),
            ("coffee", String(localized: "trigger_caffeine")),
            ("метро", String(localized: "trigger_transport")),
            ("subway", String(localized: "trigger_transport")),
            ("толпа", String(localized: "trigger_crowds")),
            ("crowd", String(localized: "trigger_crowds")),
            ("ночь", String(localized: "trigger_night")),
            ("night", String(localized: "trigger_night")),
        ]
        let triggers = Array(Set(triggerMap.compactMap { allNotes.contains($0.key) ? $0.value : nil }))

        currentRisk = PanicPrediction(
            id: UUID(), timestamp: Date(), riskLevel: level,
            confidence: conf, triggers: triggers, recommendation: rec
        )
    }
}
