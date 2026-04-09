import SwiftUI

/// Экран «Радар паники» — предсказание + аналитика
struct PanicRadarView: View {
    // MARK: Internal

    @ObservedObject
    var predictionService: PanicPredictionService

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    riskCircle
                    weeklyChart

                    if let p = predictionService.currentRisk, !p.triggers.isEmpty {
                        triggersSection(p.triggers)
                    }
                    if let p = predictionService.currentRisk {
                        recCard(p.recommendation)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Радар паники")
    }

    // MARK: Private

    // MARK: - Helpers

    private var riskColor: Color {
        switch predictionService.currentRisk?.riskLevel {
        case .low: .green
        case .moderate: .yellow
        case .high: .orange
        case .critical: .red
        case .none: .gray
        }
    }

    // MARK: - Risk circle

    private var riskCircle: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 170, height: 170)
                Circle()
                    .trim(from: 0, to: predictionService.currentRisk?.confidence ?? 0)
                    .stroke(riskColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text(predictionService.currentRisk?.riskLevel.emoji ?? "🟢")
                        .font(.system(size: 36))
                    Text(predictionService.currentRisk?.riskLevel.title ?? "…")
                        .font(.headline).foregroundColor(.white)
                }
            }
            Text("Уровень риска").font(.title3.bold()).foregroundColor(.white)
        }.padding(.top, 16)
    }

    // MARK: - Weekly

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📅 По дням недели").font(.headline).foregroundColor(.white)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(predictionService.weeklyPattern) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(day.riskScore))
                            .frame(width: 34, height: max(CGFloat(day.riskScore) * 100, 4))
                        Text(day.dayOfWeek).font(.caption2).foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Triggers

    private func triggersSection(_ triggers: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("⚡ Триггеры").font(.headline).foregroundColor(.white)
            HStack {
                ForEach(triggers, id: \.self) { t in
                    Text(t)
                        .font(.subheadline)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundColor(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14).background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recommendation

    private func recCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 Рекомендация").font(.headline).foregroundColor(.white)
            Text(text).font(.body).foregroundColor(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.primary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func barColor(_ score: Double) -> Color {
        score > 0.7 ? .red : score > 0.4 ? .orange : AppTheme.primary
    }
}
