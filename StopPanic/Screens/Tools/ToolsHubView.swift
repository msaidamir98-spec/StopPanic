import SwiftUI

// MARK: - ToolsHubView

// Единый центр всех терапевтических инструментов.
// ✨ Glassmorphism cards, staggered animations, premium button style

struct ToolsHubView: View {
    // MARK: Internal

    enum ToolCategory: String, CaseIterable {
        case emergency = "🆘 Экстренно"
        case breathing = "🌬️ Дыхание"
        case techniques = "🧠 Техники"
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
                            Text("Инструменты")
                                .font(SP.Typography.title1)
                                .foregroundColor(SP.Colors.textPrimary)
                            Text("Твой арсенал против тревоги")
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

    // MARK: - Data

    private var breathingTechniques: [BreathingTechnique] {
        [
            .init(
                name: "4-7-8 Дыхание",
                subtitle: "Самое мощное для паники",
                icon: "wind",
                color: SP.Colors.calm,
                inhale: 4,
                hold: 7,
                exhale: 8
            ),
            .init(
                name: "Квадратное дыхание",
                subtitle: "Баланс и фокус",
                icon: "square",
                color: SP.Colors.accent,
                inhale: 4,
                hold: 4,
                exhale: 4,
                holdAfter: 4
            ),
            .init(
                name: "Дыхание 2x",
                subtitle: "Выдох вдвое длиннее вдоха",
                icon: "arrow.down.heart.fill",
                color: SP.Colors.warmth,
                inhale: 4,
                hold: 0,
                exhale: 8
            ),
            .init(
                name: "Резонансное дыхание",
                subtitle: "5.5 вдохов в минуту — когерентность",
                icon: "waveform.path",
                color: SP.Colors.success,
                inhale: 5,
                hold: 0,
                exhale: 5
            ),
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
                        Text(cat.rawValue)
                            .font(SP.Typography.subheadline)
                            .foregroundColor(selectedCategory == cat ? .white : SP.Colors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(
                                    selectedCategory == cat
                                        ? AnyShapeStyle(SP.Colors.heroGradient)
                                        : AnyShapeStyle(.ultraThinMaterial)
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

    // MARK: - Emergency

    private var emergencySection: some View {
        VStack(spacing: 14) {
            ToolCard(
                icon: "hand.raised.fill",
                title: "SOS — Я в панике",
                subtitle: "Пошаговая помощь прямо сейчас",
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
                    title: "Шаги при панике",
                    subtitle: "5 текстовых шагов заземления",
                    color: SP.Colors.warmth
                )
            }

            NavigationLink {
                HeartAnalysisView()
            } label: {
                ToolCardLabel(
                    icon: "heart.text.square.fill",
                    title: "Анализ пульса",
                    subtitle: "Ритм, тревога и спокойствие",
                    color: SP.Colors.danger
                )
            }

            crisisLineCard
        }
    }

    // MARK: - Breathing

    private var breathingSection: some View {
        VStack(spacing: 14) {
            ForEach(breathingTechniques) { tech in
                NavigationLink {
                    BreathingSessionView(technique: tech)
                } label: {
                    ToolCardLabel(
                        icon: tech.icon,
                        title: tech.name,
                        subtitle: tech.subtitle,
                        color: tech.color
                    )
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
                    title: "Заземление 5-4-3-2-1",
                    subtitle: "Переключи внимание на 5 органов чувств",
                    color: SP.Colors.accent
                )
            }

            NavigationLink {
                CalmSessionView(viewModel: CalmSessionViewModel())
            } label: {
                ToolCardLabel(
                    icon: "figure.mind.and.body",
                    title: "Сессия спокойствия",
                    subtitle: "Дыхание → Заземление → Рефлексия",
                    color: SP.Colors.calm
                )
            }

            NavigationLink {
                MuscleRelaxView()
            } label: {
                ToolCardLabel(
                    icon: "figure.strengthtraining.traditional",
                    title: "Мышечная релаксация",
                    subtitle: "Прогрессивное расслабление мышц",
                    color: SP.Colors.warmth
                )
            }

            NavigationLink {
                CognitiveReframingView()
            } label: {
                ToolCardLabel(
                    icon: "brain.head.profile",
                    title: "Когнитивный рефрейминг",
                    subtitle: "Разберём тревожные мысли по полочкам",
                    color: SP.Colors.accent
                )
            }

            NavigationLink {
                PanicRadarView(predictionService: coordinator.predictionService)
            } label: {
                ToolCardLabel(
                    icon: "dot.radiowaves.left.and.right",
                    title: "Радар паники",
                    subtitle: "Предсказание на основе твоих паттернов",
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
                Text("Телефоны доверия")
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
                    Text("Позвонить")
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
