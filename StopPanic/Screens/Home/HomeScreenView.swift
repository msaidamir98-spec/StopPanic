import SwiftUI

// MARK: - HomeScreenView

// Premium UI: живые частицы, glassmorphism, spring анимации, micro-interactions.

struct HomeScreenView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.calm)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Header with greeting
                        HStack(alignment: .top) {
                            greetingSection
                            Spacer()
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .padding(.top, 8)

                        sosButtonSection
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.8)

                        statusBar
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)

                        quickActionsGrid
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 40)

                        insightCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 50)

                        progressSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 60)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, SP.Layout.padding)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
            withAnimation(SP.Anim.sosPulse) { pulseOuter = true }
            withAnimation(SP.Anim.pulse) { pulseInner = true }
            withAnimation(SP.Anim.glow) { pulseGlow = true }
        }
    }

    // MARK: Private

    @State
    private var pulseOuter = false
    @State
    private var pulseInner = false
    @State
    private var pulseGlow = false
    @State
    private var appeared = false

    private var dailyInsight: String {
        let insights = [
            String(localized: "insight_1"),
            String(localized: "insight_2"),
            String(localized: "insight_3"),
            String(localized: "insight_4"),
            String(localized: "insight_5"),
            String(localized: "insight_6"),
            String(localized: "insight_7"),
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return insights[dayOfYear % insights.count]
    }

    // MARK: - Computed helpers

    private var todayEpisodes: Int {
        coordinator.diaryService.diaryEpisodes.filter { Calendar.current.isDateInToday($0.date) }
            .count
    }

    private var weekEpisodes: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return coordinator.diaryService.diaryEpisodes.filter { $0.date >= weekAgo }.count
    }

    private var streakDays: Int {
        let calendar = Calendar.current
        let episodes = coordinator.diaryService.diaryEpisodes
        guard !episodes.isEmpty else { return 0 }

        // Get unique dates with sessions
        let sessionDates = Set(episodes.map { calendar.startOfDay(for: $0.date) })

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Check today and count backwards
        while sessionDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        // If no entry today, check if yesterday started the streak
        if streak == 0 {
            checkDate =
                calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))
                    ?? Date()
            while sessionDates.contains(checkDate) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                    break
                }
                checkDate = prev
            }
        }

        return streak
    }

    private var riskIcon: String {
        switch coordinator.predictionService.currentRisk?.riskLevel {
        case .low: "checkmark.shield.fill"
        case .moderate: "exclamationmark.shield.fill"
        case .high: "exclamationmark.triangle.fill"
        case .critical: "xmark.shield.fill"
        case .none: "shield.fill"
        }
    }

    private var riskText: String {
        coordinator.predictionService.currentRisk?.riskLevel.emoji ?? "🟢"
    }

    private var riskColor: Color {
        switch coordinator.predictionService.currentRisk?.riskLevel {
        case .low: SP.Colors.success
        case .moderate: SP.Colors.warning
        case .high: .orange
        case .critical: SP.Colors.danger
        case .none: SP.Colors.success
        }
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(coordinator.greeting)
                .font(SP.Typography.title1)
                .foregroundColor(SP.Colors.textPrimary)

            Text(coordinator.motivationalMessage)
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - SOS Button

    private var sosButtonSection: some View {
        VStack(spacing: 16) {
            Button {
                coordinator.triggerSOS()
            } label: {
                ZStack {
                    Circle()
                        .stroke(SP.Colors.danger.opacity(0.08), lineWidth: 1.5)
                        .frame(width: SP.Layout.sosButtonSize + 80)
                        .scaleEffect(pulseOuter ? 1.2 : 1.0)
                        .opacity(pulseOuter ? 0 : 0.4)

                    Circle()
                        .stroke(SP.Colors.danger.opacity(0.12), lineWidth: 2)
                        .frame(width: SP.Layout.sosButtonSize + 50)
                        .scaleEffect(pulseInner ? 1.15 : 1.0)
                        .opacity(pulseInner ? 0 : 0.5)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [SP.Colors.danger.opacity(pulseGlow ? 0.2 : 0.1), .clear],
                                center: .center, startRadius: 60,
                                endRadius: SP.Layout.sosButtonSize * 0.8
                            )
                        )
                        .frame(width: SP.Layout.sosButtonSize + 40)

                    Circle()
                        .fill(SP.Colors.sosGradient)
                        .frame(width: SP.Layout.sosButtonSize)
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: SP.Layout.sosButtonSize - 4)
                                .mask(
                                    Circle()
                                        .frame(width: SP.Layout.sosButtonSize * 0.7)
                                        .offset(x: -20, y: -30)
                                        .blur(radius: 30)
                                )
                        )
                        .shadow(color: SP.Shadows.dangerGlow, radius: pulseGlow ? 35 : 20, y: 10)

                    VStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                        Text("SOS")
                            .font(SP.Typography.sosButton)
                            .foregroundColor(.white)
                            .tracking(6)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                        Text(String(localized: "home_sos_tap"))
                            .font(SP.Typography.caption)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }
            .buttonStyle(SOSButtonStyle())

            Text(String(localized: "home_help_3sec"))
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Status Bar (Glass)

    private var statusBar: some View {
        HStack(spacing: 0) {
            statusItem(
                icon: "heart.fill", value: "\(Int(coordinator.healthManager.heartRate))",
                label: "BPM", color: SP.Colors.danger
            )
            Divider().frame(height: 30).overlay(Color.white.opacity(0.1))
            statusItem(
                icon: "flame.fill", value: "\(coordinator.sessionsCompleted)", label: String(localized: "home_sessions"),
                color: SP.Colors.warmth
            )
            Divider().frame(height: 30).overlay(Color.white.opacity(0.1))
            statusItem(
                icon: "wind", value: "\(coordinator.totalBreathingMinutes)", label: String(localized: "home_min"),
                color: SP.Colors.calm
            )
            Divider().frame(height: 30).overlay(Color.white.opacity(0.1))
            statusItem(icon: riskIcon, value: riskText, label: String(localized: "home_risk"), color: riskColor)
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home_quick_help"))
                .font(SP.Typography.title3)
                .foregroundColor(SP.Colors.textPrimary)

            LazyVGrid(
                columns: [.init(.flexible(), spacing: 12), .init(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                QuickActionCard(
                    icon: "wind", title: String(localized: "home_breathing"), subtitle: String(localized: "home_breathing_sub"),
                    color: SP.Colors.calm, gradient: SP.Colors.calmGradient
                ) { coordinator.selectedTab = .tools }
                QuickActionCard(
                    icon: "eye.fill", title: String(localized: "home_grounding"), subtitle: String(localized: "home_grounding_sub"),
                    color: SP.Colors.accent, gradient: SP.Colors.heroGradient
                ) { coordinator.selectedTab = .tools }
                QuickActionCard(
                    icon: "heart.text.square.fill", title: String(localized: "home_heart_analysis"),
                    subtitle: String(localized: "home_heart_sub"), color: SP.Colors.danger,
                    gradient: SP.Colors.sosGradient
                ) { coordinator.selectedTab = .heart }
                QuickActionCard(
                    icon: "figure.strengthtraining.traditional", title: String(localized: "home_relax"), subtitle: String(localized: "home_relax_sub"),
                    color: SP.Colors.warmth, gradient: SP.Colors.warmGradient
                ) { coordinator.selectedTab = .tools }
            }
        }
    }

    // MARK: - Insight Card

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(SP.Colors.warning)
                Text(String(localized: "home_did_you_know"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
            }

            Text(dailyInsight)
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .spGlassCard()
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home_progress"))
                .font(SP.Typography.title3)
                .foregroundColor(SP.Colors.textPrimary)

            HStack(spacing: 12) {
                ProgressMiniCard(
                    title: String(localized: "home_today"), value: "\(todayEpisodes)", subtitle: String(localized: "home_episodes"),
                    color: todayEpisodes == 0 ? SP.Colors.success : SP.Colors.warning
                )
                ProgressMiniCard(
                    title: String(localized: "home_week"), value: "\(weekEpisodes)", subtitle: String(localized: "home_episodes"),
                    color: SP.Colors.accent
                )
                ProgressMiniCard(
                    title: String(localized: "home_streak"), value: "\(streakDays)", subtitle: String(localized: "home_in_row"),
                    color: SP.Colors.calm
                )
            }
        }
    }

    private func statusItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(SP.Typography.caption2)
                .foregroundColor(SP.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - QuickActionCard

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: {
            SP.Haptic.light()
            action()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 42, height: 42)
                    Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
                }
                Text(title).font(SP.Typography.headline).foregroundColor(SP.Colors.textPrimary)
                Text(subtitle).font(SP.Typography.caption).foregroundColor(SP.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        }
        .buttonStyle(PremiumButtonStyle(scale: 0.95))
    }
}

// MARK: - ProgressMiniCard

struct ProgressMiniCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(SP.Typography.caption).foregroundColor(SP.Colors.textTertiary)
            Text(value).font(SP.Typography.title2).foregroundColor(color).contentTransition(
                .numericText()
            )
            Text(subtitle).font(SP.Typography.caption2).foregroundColor(SP.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
    }
}

// MARK: - SOSButtonStyle

struct SOSButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
