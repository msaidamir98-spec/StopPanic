import SwiftUI

// MARK: - ToolsHubView

// Единый центр всех инструментов самопомощи.
// ✨ Glassmorphism cards, premium gates, staggered animations

struct ToolsHubView: View {
    // MARK: Internal

    enum ToolCategory: String, CaseIterable {
        case emergency, breathing, techniques

        // MARK: Internal

        var title: String {
            switch self {
            case .emergency: "🆘 " + String(localized: "tools_cat_emergency")
            case .breathing: "🌬️ " + String(localized: "tools_cat_breathing")
            case .techniques: "🧠 " + String(localized: "tools_cat_techniques")
            }
        }
    }

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.calm)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(String(localized: "tools_title"))
                                .font(SP.Typography.title1)
                                .foregroundColor(SP.Colors.textPrimary)
                            Text(String(localized: "tools_subtitle"))
                                .font(SP.Typography.callout)
                                .foregroundColor(SP.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : -15)

                        // Category pills
                        categoryPills
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : -10)

                        // Tools grid
                        toolsContent
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)
                    }
                    .padding(.horizontal, SP.Layout.padding)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appear = true
                }
            }
        }
    }

    // MARK: Private

    @State
    private var selectedCategory: ToolCategory = .emergency
    @State
    private var appear = false

    private var isPremium: Bool {
        coordinator.premiumManager.isPremium
    }

    // MARK: - Data

    private var breathingTechniques: [(tech: BreathingTechnique, free: Bool)] {
        [
            (.init(
                name: String(localized: "breath_478_name"),
                subtitle: String(localized: "breath_478_sub"),
                icon: "wind",
                color: SP.Colors.calm,
                inhale: 4, hold: 7, exhale: 8
            ), true), // FREE
            (.init(
                name: String(localized: "breath_box_name"),
                subtitle: String(localized: "breath_box_sub"),
                icon: "square",
                color: SP.Colors.accent,
                inhale: 4, hold: 4, exhale: 4, holdAfter: 4
            ), false), // PREMIUM
            (.init(
                name: String(localized: "breath_2x_name"),
                subtitle: String(localized: "breath_2x_sub"),
                icon: "arrow.down.heart.fill",
                color: SP.Colors.warmth,
                inhale: 4, hold: 0, exhale: 8
            ), false), // PREMIUM
            (.init(
                name: String(localized: "breath_resonance_name"),
                subtitle: String(localized: "breath_resonance_sub"),
                icon: "waveform.path",
                color: SP.Colors.success,
                inhale: 5, hold: 0, exhale: 5
            ), false), // PREMIUM
        ]
    }

    // MARK: - Category Pills

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ToolCategory.allCases, id: \.self) { cat in
                    Button {
                        SP.Haptic.selectionChanged()
                        withAnimation(SP.Anim.springSnappy) {
                            selectedCategory = cat
                        }
                    } label: {
                        Text(cat.title)
                            .font(SP.Typography.subheadline)
                            .foregroundColor(selectedCategory == cat ? .white : SP.Colors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(
                                    selectedCategory == cat
                                        ? AnyShapeStyle(SP.Colors.heroGradient)
                                        : AnyShapeStyle(.warmGlass)
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedCategory == cat
                                            ? SP.Colors.accent.opacity(0.4)
                                            : Color.white.opacity(0.08),
                                        lineWidth: 0.5
                                    )
                            )
                    }
                    .buttonStyle(PremiumButtonStyle())
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var toolsContent: some View {
        switch selectedCategory {
        case .emergency:
            emergencySection
        case .breathing:
            breathingSection
        case .techniques:
            techniquesSection
        }
    }

    // MARK: - Emergency (always free)

    private var emergencySection: some View {
        VStack(spacing: 14) {
            ToolCard(
                icon: "hand.raised.fill",
                title: String(localized: "tools_sos_title"),
                subtitle: String(localized: "tools_sos_sub"),
                color: SP.Colors.danger,
                isLarge: true
            ) {
                coordinator.triggerSOS()
            }

            NavigationLink {
                NowHelpView(viewModel: NowHelpViewModel())
            } label: {
                ToolCardLabel(
                    icon: "list.number",
                    title: String(localized: "tools_steps_title"),
                    subtitle: String(localized: "tools_steps_sub"),
                    color: SP.Colors.warmth
                )
            }

            NavigationLink {
                HeartAnalysisView()
            } label: {
                ToolCardLabel(
                    icon: "heart.text.square.fill",
                    title: String(localized: "tools_heart_title"),
                    subtitle: String(localized: "tools_heart_sub"),
                    color: SP.Colors.danger
                )
            }

            crisisLineCard
        }
    }

    // MARK: - Breathing (first free, rest premium)

    private var breathingSection: some View {
        VStack(spacing: 14) {
            ForEach(Array(breathingTechniques.enumerated()), id: \.element.tech.id) { _, item in
                let isAccessible = item.free || isPremium

                if isAccessible {
                    NavigationLink {
                        BreathingSessionView(technique: item.tech)
                    } label: {
                        ToolCardLabel(
                            icon: item.tech.icon,
                            title: item.tech.name,
                            subtitle: item.tech.subtitle,
                            color: item.tech.color
                        )
                    }
                } else {
                    Button {
                        coordinator.showPaywall = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(item.tech.color.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: item.tech.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(item.tech.color)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(item.tech.name)
                                        .font(SP.Typography.headline)
                                        .foregroundColor(SP.Colors.textPrimary)
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                }
                                Text(item.tech.subtitle)
                                    .font(SP.Typography.caption)
                                    .foregroundColor(SP.Colors.textTertiary)
                            }

                            Spacer()

                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
                    }
                    .buttonStyle(PremiumButtonStyle())
                }
            }
        }
    }

    // MARK: - Techniques

    private var techniquesSection: some View {
        VStack(spacing: 14) {
            NavigationLink {
                GroundingExerciseView()
            } label: {
                ToolCardLabel(
                    icon: "eye.fill",
                    title: String(localized: "tools_grounding_title"),
                    subtitle: String(localized: "tools_grounding_sub"),
                    color: SP.Colors.accent
                )
            }

            NavigationLink {
                CalmSessionView(viewModel: CalmSessionViewModel())
            } label: {
                ToolCardLabel(
                    icon: "figure.mind.and.body",
                    title: String(localized: "tools_calm_title"),
                    subtitle: String(localized: "tools_calm_sub"),
                    color: SP.Colors.calm
                )
            }

            if isPremium {
                NavigationLink {
                    MuscleRelaxView()
                } label: {
                    ToolCardLabel(
                        icon: "figure.strengthtraining.traditional",
                        title: String(localized: "tools_muscle_title"),
                        subtitle: String(localized: "tools_muscle_sub"),
                        color: SP.Colors.warmth
                    )
                }

                NavigationLink {
                    CognitiveReframingView()
                } label: {
                    ToolCardLabel(
                        icon: "brain.head.profile",
                        title: String(localized: "tools_cognitive_title"),
                        subtitle: String(localized: "tools_cognitive_sub"),
                        color: SP.Colors.accent
                    )
                }
            } else {
                // Locked premium items
                premiumLockedCard(
                    icon: "figure.strengthtraining.traditional",
                    title: String(localized: "tools_muscle_title"),
                    subtitle: String(localized: "tools_muscle_sub"),
                    color: SP.Colors.warmth
                )
                premiumLockedCard(
                    icon: "brain.head.profile",
                    title: String(localized: "tools_cognitive_title"),
                    subtitle: String(localized: "tools_cognitive_sub"),
                    color: SP.Colors.accent
                )
            }

            NavigationLink {
                PanicRadarView(predictionService: coordinator.predictionService)
            } label: {
                ToolCardLabel(
                    icon: "chart.bar.xaxis",
                    title: String(localized: "tools_patterns_title"),
                    subtitle: String(localized: "tools_patterns_sub"),
                    color: SP.Colors.accent
                )
            }
        }
    }

    // MARK: - Crisis

    private var crisisLineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(SP.Colors.success)
                Text(String(localized: "tools_crisis_title"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }

            let line = SOSService.getCrisisLine()
            Button {
                if let url = URL(string: "tel://\(line.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: ""))") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text("📞 \(line)")
                        .font(SP.Typography.title3)
                        .foregroundColor(SP.Colors.success)
                    Spacer()
                    Text(String(localized: "tools_crisis_call"))
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.success)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(SP.Colors.success.opacity(0.15)))
                }
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    private func premiumLockedCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        Button {
            coordinator.showPaywall = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.textPrimary)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    Text(subtitle)
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        }
        .buttonStyle(PremiumButtonStyle())
    }
}

// MARK: - BreathingTechnique

struct BreathingTechnique: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let inhale: TimeInterval
    let hold: TimeInterval
    let exhale: TimeInterval
    var holdAfter: TimeInterval = 0

    var totalCycleDuration: TimeInterval {
        inhale + hold + exhale + holdAfter
    }
}

// MARK: - ToolCard

struct ToolCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isLarge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            SP.Haptic.medium()
            action()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: isLarge ? 56 : 44, height: isLarge ? 56 : 44)
                    Image(systemName: icon)
                        .font(.system(size: isLarge ? 24 : 18))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(isLarge ? SP.Typography.title3 : SP.Typography.headline)
                        .foregroundColor(SP.Colors.textPrimary)
                    Text(subtitle)
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        }
        .buttonStyle(PremiumButtonStyle())
    }
}

// MARK: - ToolCardLabel

struct ToolCardLabel: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isLarge: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: isLarge ? 56 : 44, height: isLarge ? 56 : 44)
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 24 : 18))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(isLarge ? SP.Typography.title3 : SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Text(subtitle)
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(SP.Colors.textTertiary)
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }
}
