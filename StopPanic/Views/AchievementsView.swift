import SwiftUI

// MARK: - AchievementsView

/// Экран достижений — геймификация прогресса.
struct AchievementsView: View {
    // MARK: Internal

    @ObservedObject
    var service: AchievementService

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.warning, secondaryColor: SP.Colors.accent)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 10) {
                        Text("🏆")
                            .font(.system(size: 50))
                            .scaleEffect(appear ? 1 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.5), value: appear)
                        AnimatedNumber(
                            value: service.totalPoints,
                            font: SP.Typography.heroTitle,
                            color: SP.Colors.warning
                        )
                        Text(
                            String(
                                localized: "achievements.unlocked_count \(service.achievements.filter(\.isUnlocked).count) \(service.achievements.count)"
                            )
                        )
                        .font(SP.Typography.subheadline)
                        .foregroundColor(SP.Colors.textSecondary)
                    }
                    .padding(.top, 12)
                    .opacity(appear ? 1 : 0)

                    // Grid
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(service.achievements.enumerated()), id: \.element.id) { index, a in
                            achievementCard(a)
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 20)
                                .animation(SP.Anim.spring.delay(Double(index) * 0.05), value: appear)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, SP.Layout.padding)
            }
        }
        .navigationTitle(String(localized: "achievements.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
    }

    // MARK: Private

    @State
    private var appear = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    private func achievementCard(_ a: Achievement) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(a.isUnlocked ? SP.Colors.accent.opacity(0.2) : SP.Colors.bgCardHover)
                    .frame(width: 52, height: 52)
                    .shadow(color: a.isUnlocked ? SP.Colors.accent.opacity(0.3) : .clear, radius: 8)
                Image(systemName: a.icon)
                    .font(.system(size: 20))
                    .foregroundColor(a.isUnlocked ? SP.Colors.accent : SP.Colors.textTertiary)
            }

            Text(a.title)
                .font(SP.Typography.subheadline)
                .foregroundColor(a.isUnlocked ? SP.Colors.textPrimary : SP.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(a.description)
                .font(SP.Typography.caption2)
                .foregroundColor(SP.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if !a.isUnlocked {
                ProgressView(value: a.progress)
                    .tint(SP.Colors.accent)
                Text("\(a.currentProgress)/\(a.requirement)")
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
                    .monospacedDigit()
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                    Text(String(localized: "achievements.unlocked"))
                        .font(SP.Typography.caption2)
                }
                .foregroundColor(SP.Colors.success)
            }
        }
        .padding(14)
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .overlay(
            RoundedRectangle(cornerRadius: SP.Layout.cornerMedium, style: .continuous)
                .stroke(a.isUnlocked ? SP.Colors.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
