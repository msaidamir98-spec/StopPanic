import SwiftUI

// MARK: - Onboarding Flow — Premium WOW

// Персонализированный онбординг с particle effects, staggered animations,
// glassmorphism cards, haptic feedback на каждом шаге.

struct OnboardingFlowView: View {
    // MARK: Internal

    enum PanicExperience: String, CaseIterable {
        case first = "Впервые"
        case rare = "Редко (пару раз)"
        case sometimes = "Иногда"
        case often = "Часто"
        case daily = "Почти каждый день"

        // MARK: Internal

        var emoji: String {
            switch self {
            case .first: "🌱"
            case .rare: "🌤️"
            case .sometimes: "⛅"
            case .often: "🌧️"
            case .daily: "⛈️"
            }
        }
    }

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.calm)

            VStack(spacing: 0) {
                // Progress
                progressBar
                    .padding(.top, 12)
                    .opacity(showContent ? 1 : 0)

                // Pages
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    namePage.tag(1)
                    experiencePage.tag(2)
                    goalsPage.tag(3)
                    readyPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(SP.Anim.spring, value: currentPage)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                showContent = true
                logoScale = 1.0
                logoRotation = 0
            }
        }
    }

    // MARK: Private

    @State
    private var currentPage = 0
    @State
    private var userName = ""
    @State
    private var selectedExperience: PanicExperience?
    @State
    private var selectedGoals: Set<String> = []
    @State
    private var showContent = false
    @State
    private var logoScale: CGFloat = 0.3
    @State
    private var logoRotation: Double = -30

    private let goals = [
        ("🫁", "Научиться дышать при панике"),
        ("💓", "Понимать свой пульс и тревогу"),
        ("📝", "Вести дневник тревоги"),
        ("🧠", "Разобрать тревожные мысли"),
        ("😌", "Снизить общую тревожность"),
        ("🆘", "Иметь план на случай паники"),
    ]

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 5, id: \.self) { i in
                Capsule()
                    .fill(i <= currentPage ? SP.Colors.accent : Color.white.opacity(0.1))
                    .frame(height: 4)
                    .overlay(
                        Capsule()
                            .fill(i <= currentPage ? SP.Colors.accent : Color.clear)
                            .shadow(
                                color: SP.Colors.accent.opacity(i <= currentPage ? 0.5 : 0),
                                radius: 4
                            )
                    )
                    .animation(SP.Anim.springSnappy.delay(Double(i) * 0.05), value: currentPage)
            }
        }
        .padding(.horizontal, SP.Layout.padding)
    }

    // MARK: - Page 0: Welcome

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated Logo
            ZStack {
                // Outer glow rings
                ForEach(0 ..< 3, id: \.self) { i in
                    Circle()
                        .stroke(SP.Colors.accent.opacity(0.08 - Double(i) * 0.02), lineWidth: 1)
                        .frame(width: CGFloat(120 + i * 30), height: CGFloat(120 + i * 30))
                        .scaleEffect(showContent ? 1 : 0.5)
                        .animation(SP.Anim.spring.delay(0.3 + Double(i) * 0.15), value: showContent)
                }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                SP.Colors.accent.opacity(0.2), SP.Colors.accent.opacity(0.05),
                            ],
                            center: .center, startRadius: 10, endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 50))
                    .foregroundColor(SP.Colors.accent)
                    .scaleEffect(logoScale)
                    .rotationEffect(.degrees(logoRotation))
            }

            VStack(spacing: 12) {
                Text("StopPanic")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(SP.Colors.textPrimary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(SP.Anim.spring.delay(0.2), value: showContent)

                Text("Твой карманный щит\nпротив панических атак")
                    .font(SP.Typography.title3)
                    .foregroundColor(SP.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(SP.Anim.spring.delay(0.35), value: showContent)
            }

            // Feature lines with staggered animation
            VStack(alignment: .leading, spacing: 14) {
                featureLine(
                    "🆘", "Помощь за 3 секунды", "Одна кнопка — моментальная помощь", delay: 0.5
                )
                featureLine("💓", "Мониторинг пульса", "Анализ ритма и дыхательный тест", delay: 0.6)
                featureLine("📝", "Дневник тревоги", "Отслеживай паттерны и прогресс", delay: 0.7)
                featureLine("⌚", "Apple Watch", "Мониторинг пульса на запястье", delay: 0.8)
            }
            .padding(.horizontal, 8)

            Spacer()

            nextButton("Начнём →")
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(SP.Anim.spring.delay(0.9), value: showContent)
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Page 1: Name

    private var namePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("👋")
                .font(.system(size: 64))
                .scaleEffect(currentPage == 1 ? 1 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: currentPage)

            Text("Как тебя зовут?")
                .font(SP.Typography.heroTitle)
                .foregroundColor(SP.Colors.textPrimary)

            Text("Так я смогу обращаться лично")
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)

            TextField("Имя", text: $userName)
                .textFieldStyle(.plain)
                .font(SP.Typography.title2)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                )
                .foregroundColor(.white)
                .padding(.horizontal, 40)

            Spacer()

            nextButton(userName.isEmpty ? "Пропустить" : "Далее →")
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Page 2: Experience

    private var experiencePage: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("Как часто ты испытываешь\nпанические атаки?")
                .font(SP.Typography.title1)
                .foregroundColor(SP.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Это поможет настроить приложение")
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)

            VStack(spacing: 10) {
                ForEach(Array(PanicExperience.allCases.enumerated()), id: \.element) { index, exp in
                    Button {
                        SP.Haptic.selectionChanged()
                        withAnimation(SP.Anim.springSnappy) {
                            selectedExperience = exp
                        }
                    } label: {
                        HStack {
                            Text(exp.emoji)
                                .font(.title3)
                            Text(exp.rawValue)
                                .font(SP.Typography.headline)
                                .foregroundColor(
                                    selectedExperience == exp ? .white : SP.Colors.textSecondary
                                )
                            Spacer()
                            if selectedExperience == exp {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    selectedExperience == exp
                                        ? AnyShapeStyle(SP.Colors.heroGradient)
                                        : AnyShapeStyle(.ultraThinMaterial)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    selectedExperience == exp
                                        ? SP.Colors.accent.opacity(0.5)
                                        : Color.white.opacity(0.08),
                                    lineWidth: 0.5
                                )
                        )
                    }
                    .buttonStyle(PremiumButtonStyle())
                    .opacity(currentPage == 2 ? 1 : 0)
                    .offset(y: currentPage == 2 ? 0 : 20)
                    .animation(SP.Anim.spring.delay(Double(index) * 0.08), value: currentPage)
                }
            }

            Spacer()

            nextButton("Далее →")
                .opacity(selectedExperience != nil ? 1 : 0.5)
                .disabled(selectedExperience == nil)
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Page 3: Goals

    private var goalsPage: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("Чего ты хочешь достичь?")
                .font(SP.Typography.title1)
                .foregroundColor(SP.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Выбери одну или несколько целей")
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                ForEach(Array(goals.enumerated()), id: \.element.1) { index, goal in
                    let (emoji, title) = goal
                    let isSelected = selectedGoals.contains(title)

                    Button {
                        SP.Haptic.selectionChanged()
                        withAnimation(SP.Anim.springSnappy) {
                            if isSelected {
                                selectedGoals.remove(title)
                            } else {
                                selectedGoals.insert(title)
                            }
                        }
                    } label: {
                        goalCardLabel(emoji: emoji, title: title, isSelected: isSelected)
                    }
                    .buttonStyle(PremiumButtonStyle())
                    .opacity(currentPage == 3 ? 1 : 0)
                    .offset(y: currentPage == 3 ? 0 : 20)
                    .animation(SP.Anim.spring.delay(Double(index) * 0.06), value: currentPage)
                }
            }

            Spacer()

            nextButton("Далее →")
                .opacity(selectedGoals.isEmpty ? 0.5 : 1)
                .disabled(selectedGoals.isEmpty)
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Page 4: Ready

    private var readyPage: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                // Celebration rings
                ForEach(0 ..< 3, id: \.self) { i in
                    Circle()
                        .stroke(SP.Colors.success.opacity(0.1 - Double(i) * 0.03), lineWidth: 1)
                        .frame(width: CGFloat(130 + i * 25), height: CGFloat(130 + i * 25))
                        .scaleEffect(currentPage == 4 ? 1 : 0.5)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.5).delay(
                                0.2 + Double(i) * 0.1
                            ), value: currentPage
                        )
                }

                Circle()
                    .fill(SP.Colors.success.opacity(0.12))
                    .frame(width: 130, height: 130)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 56))
                    .foregroundColor(SP.Colors.success)
                    .scaleEffect(currentPage == 4 ? 1 : 0.3)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.5).delay(0.1), value: currentPage
                    )
            }

            Text("Всё готово\(userName.isEmpty ? "" : ", \(userName)")!")
                .font(SP.Typography.heroTitle)
                .foregroundColor(SP.Colors.textPrimary)

            Text(
                "Твоё приложение настроено.\nСОС-кнопка всегда на главном экране.\n\nТы больше не один."
            )
            .font(SP.Typography.body)
            .foregroundColor(SP.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)

            // Important note — glass card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Важно")
                        .font(SP.Typography.headline)
                        .foregroundColor(SP.Colors.textPrimary)
                }
                Text(
                    "StopPanic — помощник, НЕ замена врачу. При подозрении на сердечную проблему всегда вызывайте скорую."
                )
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textSecondary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)

            Spacer()

            Button {
                SP.Haptic.success()
                coordinator.userName = userName
                coordinator.panicExperience = selectedExperience?.rawValue ?? "sometimes"
                coordinator.notificationService.requestAuthorization()
                coordinator.healthManager.requestPermissions()
                withAnimation(SP.Anim.spring) {
                    coordinator.hasSeenOnboarding = true
                }
            } label: {
                Text("Начать использовать")
                    .spPrimaryButton()
            }
            .glowPulse(color: SP.Colors.success)
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    private func featureLine(
        _ emoji: String, _ title: String, _ subtitle: String, delay: Double = 0
    ) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Text(subtitle)
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textTertiary)
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(x: showContent ? 0 : -30)
        .animation(SP.Anim.spring.delay(delay), value: showContent)
    }

    // MARK: - Reusable Next Button

    private func nextButton(_ title: String) -> some View {
        Button {
            SP.Haptic.soft()
            withAnimation(SP.Anim.spring) {
                currentPage += 1
            }
        } label: {
            Text(title)
                .spPrimaryButton()
        }
        .buttonStyle(PremiumButtonStyle())
    }

    // MARK: - Goal Card Label (extracted for type-checker)

    private func goalCardLabel(emoji: String, title: String, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.title)
                .scaleEffect(isSelected ? 1.15 : 1.0)
            Text(title)
                .font(SP.Typography.caption)
                .foregroundColor(isSelected ? .white : SP.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isSelected
                        ? AnyShapeStyle(SP.Colors.heroGradient)
                        : AnyShapeStyle(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isSelected
                        ? SP.Colors.accent.opacity(0.5) : Color.white.opacity(0.08),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        )
        .shadow(
            color: isSelected ? SP.Colors.accent.opacity(0.2) : .clear,
            radius: 8, y: 4
        )
    }
}
