import SwiftUI

// MARK: - PanicRadarView

/// Экран «Радар паники» — предсказание + аналитика на основе дневника.
struct PanicRadarView: View {
    // MARK: Internal

    @ObservedObject
    var predictionService: PanicPredictionService

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.calm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    riskCircle
                        .opacity(appear ? 1 : 0)
                        .scaleEffect(appear ? 1 : 0.8)

                    weeklyChart
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                    if let p = predictionService.currentRisk, !p.triggers.isEmpty {
                        triggersSection(p.triggers)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 30)
                    }

                    if let p = predictionService.currentRisk {
                        recCard(p.recommendation)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 40)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.top, 16)
            }
        }
        .navigationTitle(String(localized: "radar.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { appear = true }
        }
    }

    // MARK: Private

    @State
    private var appear = false

    private var riskColor: Color {
        switch predictionService.currentRisk?.riskLevel {
        case .low: SP.Colors.success
        case .moderate: SP.Colors.warning
        case .high: .orange
        case .critical: SP.Colors.danger
        case .none: SP.Colors.textTertiary
        }
    }

    // MARK: - Risk Circle

    private var riskCircle: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(SP.Colors.bgCardHover, lineWidth: 10)
                    .frame(width: 170, height: 170)
                Circle()
                    .trim(from: 0, to: predictionService.currentRisk?.confidence ?? 0)
                    .stroke(riskColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))
                    .animation(SP.Anim.spring, value: predictionService.currentRisk?.confidence)
                VStack(spacing: 6) {
                    Text(predictionService.currentRisk?.riskLevel.emoji ?? "🟢")
                        .font(.system(size: 36))
                    Text(predictionService.currentRisk?.riskLevel.title ?? "…")
                        .font(SP.Typography.headline)
                        .foregroundColor(SP.Colors.textPrimary)
                }
            }
            Text(String(localized: "radar.risk_level"))
                .font(SP.Typography.title3)
                .foregroundColor(SP.Colors.textPrimary)
        }
        .padding(.top, 8)
    }

    // MARK: - Weekly Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(SP.Colors.accent)
                Text(String(localized: "radar.by_weekday"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(predictionService.weeklyPattern) { day in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(day.riskScore))
                            .frame(width: 34, height: max(CGFloat(day.riskScore) * 100, 6))
                        Text(day.dayOfWeek)
                            .font(SP.Typography.caption2)
                            .foregroundColor(SP.Colors.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    // MARK: - Triggers

    private func triggersSection(_ triggers: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(SP.Colors.warning)
                Text(String(localized: "radar.triggers"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }
            HStack(spacing: 8) {
                ForEach(triggers, id: \.self) { t in
                    Text(t)
                        .font(SP.Typography.subheadline)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    // MARK: - Recommendation

    private func recCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(SP.Colors.warning)
                Text(String(localized: "radar.recommendation"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }
            Text(text)
                .font(SP.Typography.body)
                .foregroundColor(SP.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    private func barColor(_ score: Double) -> Color {
        score > 0.7 ? SP.Colors.danger : score > 0.4 ? .orange : SP.Colors.accent
    }
}
