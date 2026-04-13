import SwiftUI

// MARK: - Onboarding Flow — Value First

// Бестселлер-подход:
// Page 0: Welcome — крутой визуал + "Попробуй прямо сейчас"
// Page 1: Mini Breathing — 30 сек дыхание 4-7-8 (VALUE!)
// Page 2: Result — "Видишь? Пульс снизился. Это работает."
// Page 3: Name — теперь можно спросить имя (trust earned)
// Page 4: Experience + Goals (combined, быстрее)
// Page 5: Ready + Notifications permission

struct OnboardingFlowView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.calm)

            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 12)
                    .opacity(showContent ? 1 : 0)

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    miniBreathingPage.tag(1)
                    resultPage.tag(2)
                    namePage.tag(3)
                    experiencePage.tag(4)
                    readyPage.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(SP.Anim.spring, value: currentPage)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                showContent = true
                logoScale = 1.0
            }
        }
        .onChange(of: currentPage) { _, newPage in
            if newPage != 1 {
                stopMiniBreathing()
            }
        }
    }

    // MARK: Private

    @State private var currentPage = 0
    @State private var userName = ""
    @State private var selectedExperience: String?
    @State private var showContent = false
    @State private var logoScale: CGFloat = 0.3

    // Mini breathing state
    @State private var breathScale: CGFloat = 0.4
    @State private var breathPhase = String(localized: "onb_tap_start")
    @State private var isBreathing = false
    @State private var breathCycles = 0
    @State private var breathTimer: Timer?
    @State private var miniBreathComplete = false

    private let experiences = [
        ("🌱", String(localized: "onb_exp_first")),
        ("🌤️", String(localized: "onb_exp_rare")),
        ("⛅", String(localized: "onb_exp_sometimes")),
        ("🌧️", String(localized: "onb_exp_often")),
        ("⛈️", String(localized: "onb_exp_daily")),
    ]

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 6, id: \.self) { i in
                Capsule()
                    .fill(i <= currentPage ? SP.Colors.accent : SP.Colors.textTertiary.opacity(0.2))
                    .frame(height: 4)
                    .animation(SP.Anim.springSnappy.delay(Double(i) * 0.05), value: currentPage)
            }
        }
        .padding(.horizontal, SP.Layout.padding)
    }

    // MARK: - Page 0: Welcome

    private var welcomePage: some View {
        VStack(spacing: 28) {
            Spacer()

            // Logo
            ZStack {
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
                            colors: [SP.Colors.accent.opacity(0.2), SP.Colors.accent.opacity(0.05)],
                            center: .center, startRadius: 10, endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 50))
                    .foregroundColor(SP.Colors.accent)
                    .scaleEffect(logoScale)
            }

            VStack(spacing: 12) {
                Text("Stillō")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(SP.Colors.textPrimary)

                Text(String(localized: "onb_tagline"))
                    .font(SP.Typography.title3)
                    .foregroundColor(SP.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Quick value props
            VStack(alignment: .leading, spacing: 14) {
                featureLine("🆘", String(localized: "onb_feature_sos"), String(localized: "onb_feature_sos_sub"), delay: 0.5)
                featureLine("💓", String(localized: "onb_feature_heart"), String(localized: "onb_feature_heart_sub"), delay: 0.6)
                featureLine("🫁", String(localized: "onb_feature_breath"), String(localized: "onb_feature_breath_sub"), delay: 0.7)
            }
            .padding(.horizontal, 8)

            Spacer()

            // CTA — "Попробуй прямо сейчас"
            nextButton(String(localized: "onb_try_now"))
                .opacity(showContent ? 1 : 0)
                .animation(SP.Anim.spring.delay(0.9), value: showContent)
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Page 1: Mini Breathing (VALUE FIRST!)

    private var miniBreathingPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(String(localized: "onb_breath_title"))
                .font(SP.Typography.title1)
                .foregroundColor(SP.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "onb_breath_subtitle"))
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)

            // Breathing circle
            ZStack {
                // Outer glow
                Circle()
                    .fill(SP.Colors.calm.opacity(0.06))
                    .frame(width: 260, height: 260)
                    .scaleEffect(breathScale * 1.2)

                // Ring
                Circle()
                    .stroke(SP.Colors.calm.opacity(0.15), lineWidth: 3)
                    .frame(width: 200, height: 200)

                // Main circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [SP.Colors.calm.opacity(0.3), SP.Colors.calm.opacity(0.05)],
                            center: .center, startRadius: 20, endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(breathScale)

                // Phase text
                VStack(spacing: 8) {
                    Text(breathPhase)
                        .font(SP.Typography.title2)
                        .foregroundColor(SP.Colors.textPrimary)

                    if isBreathing {
                        Text("\(breathCycles)/3")
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.textTertiary)
                    }
                }
            }

            Spacer()

            if miniBreathComplete {
                nextButton(String(localized: "onb_breath_done_next"))
                    .transition(.scale.combined(with: .opacity))
            } else if !isBreathing {
                Button {
                    startMiniBreathing()
                } label: {
                    Text(String(localized: "onb_breath_start"))
                        .spPrimaryButton()
                }
                .buttonStyle(PremiumButtonStyle())
                .glowPulse(color: SP.Colors.calm)
            } else {
                Text(String(localized: "onb_breath_follow"))
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textTertiary)
            }
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Page 2: Result

    private var resultPage: some View {
        VStack(spacing: 28) {
            Spacer()

            // Checkmark animation
            ZStack {
                Circle()
                    .fill(SP.Colors.success.opacity(0.12))
                    .frame(width: 130, height: 130)
                    .scaleEffect(currentPage == 2 ? 1 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: currentPage)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(SP.Colors.success)
                    .scaleEffect(currentPage == 2 ? 1 : 0.3)
                    .animation(.spring(response: 0.7, dampingFraction: 0.4).delay(0.15), value: currentPage)
            }

            VStack(spacing: 12) {
                Text(String(localized: "onb_result_title"))
                    .font(SP.Typography.heroTitle)
                    .foregroundColor(SP.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(String(localized: "onb_result_subtitle"))
                    .font(SP.Typography.body)
                    .foregroundColor(SP.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Science card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(SP.Colors.accent)
                    Text(String(localized: "onb_result_science_title"))
                        .font(SP.Typography.headline)
                        .foregroundColor(SP.Colors.textPrimary)
                }
                Text(String(localized: "onb_result_science_body"))
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textSecondary)
                    .lineSpacing(3)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)

            Spacer()

            nextButton(String(localized: "onb_continue"))
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Page 3: Name (trust earned)

    private var namePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("👋")
                .font(.system(size: 64))
                .scaleEffect(currentPage == 3 ? 1 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: currentPage)

            Text(String(localized: "onb_name_title"))
                .font(SP.Typography.heroTitle)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "onb_name_subtitle"))
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)

            TextField(String(localized: "onb_name_placeholder"), text: $userName)
                .textFieldStyle(.plain)
                .font(SP.Typography.title2)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.warmGlass)
                )
                .foregroundColor(SP.Colors.textPrimary)
                .padding(.horizontal, 40)

            Spacer()

            nextButton(userName.isEmpty ? String(localized: "onb_skip") : String(localized: "onb_next"))
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Page 4: Experience (simplified)

    private var experiencePage: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(String(localized: "onb_exp_title"))
                .font(SP.Typography.title1)
                .foregroundColor(SP.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "onb_exp_subtitle"))
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)

            VStack(spacing: 10) {
                ForEach(Array(experiences.enumerated()), id: \.element.1) { index, exp in
                    let isSelected = selectedExperience == exp.1

                    Button {
                        SP.Haptic.selectionChanged()
                        withAnimation(SP.Anim.springSnappy) {
                            selectedExperience = exp.1
                        }
                    } label: {
                        HStack {
                            Text(exp.0).font(.title3)
                            Text(exp.1)
                                .font(SP.Typography.headline)
                                .foregroundColor(isSelected ? .white : SP.Colors.textSecondary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? AnyShapeStyle(SP.Colors.heroGradient) : AnyShapeStyle(.warmGlass))
                        )
                    }
                    .buttonStyle(PremiumButtonStyle())
                    .opacity(currentPage == 4 ? 1 : 0)
                    .offset(y: currentPage == 4 ? 0 : 20)
                    .animation(SP.Anim.spring.delay(Double(index) * 0.08), value: currentPage)
                }
            }

            Spacer()

            nextButton(String(localized: "onb_next"))
                .opacity(selectedExperience != nil ? 1 : 0.5)
                .disabled(selectedExperience == nil)
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Page 5: Ready

    private var readyPage: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                ForEach(0 ..< 3, id: \.self) { i in
                    Circle()
                        .stroke(SP.Colors.success.opacity(0.1 - Double(i) * 0.03), lineWidth: 1)
                        .frame(width: CGFloat(130 + i * 25), height: CGFloat(130 + i * 25))
                        .scaleEffect(currentPage == 5 ? 1 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.2 + Double(i) * 0.1), value: currentPage)
                }

                Circle()
                    .fill(SP.Colors.success.opacity(0.12))
                    .frame(width: 130, height: 130)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 56))
                    .foregroundColor(SP.Colors.success)
                    .scaleEffect(currentPage == 5 ? 1 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1), value: currentPage)
            }

            Text(String(localized: "onb_ready_title \(userName.isEmpty ? "" : userName)"))
                .font(SP.Typography.heroTitle)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "onb_ready_subtitle"))
                .font(SP.Typography.body)
                .foregroundColor(SP.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Medical disclaimer
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(String(localized: "onb_disclaimer_title"))
                        .font(SP.Typography.headline)
                        .foregroundColor(SP.Colors.textPrimary)
                }
                Text(String(localized: "onb_disclaimer_body"))
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textSecondary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)

            Spacer()

            Button {
                SP.Haptic.success()
                coordinator.userName = userName
                coordinator.panicExperience = selectedExperience ?? "sometimes"
                coordinator.notificationService.requestAuthorization()
                coordinator.healthManager.requestPermissions()
                withAnimation(SP.Anim.spring) {
                    coordinator.hasSeenOnboarding = true
                }
            } label: {
                Text(String(localized: "onb_start_using"))
                    .spPrimaryButton()
            }
            .glowPulse(color: SP.Colors.success)
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Helpers

    private func featureLine(_ emoji: String, _ title: String, _ subtitle: String, delay: Double) -> some View {
        HStack(spacing: 14) {
            Text(emoji).font(.title2).frame(width: 36)
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

    // MARK: - Mini Breathing Engine (30-sec 4-7-8)

    private func startMiniBreathing() {
        isBreathing = true
        breathCycles = 0
        runBreathCycle()
    }

    private func stopMiniBreathing() {
        isBreathing = false
        breathCycles = 0
    }

    private func runBreathCycle() {
        guard breathCycles < 3 else {
            // Complete!
            isBreathing = false
            withAnimation(SP.Anim.spring) {
                miniBreathComplete = true
                breathPhase = String(localized: "onb_breath_complete")
            }
            SP.Haptic.success()
            return
        }

        // Inhale (4s)
        breathPhase = String(localized: "breath_inhale")
        SP.Haptic.soft()
        withAnimation(.easeInOut(duration: 4)) { breathScale = 1.0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [self] in
            guard isBreathing else { return }
            // Hold (4s instead of 7 for mini)
            breathPhase = String(localized: "breath_hold")
            SP.Haptic.light()

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [self] in
                guard isBreathing else { return }
                // Exhale (4s instead of 8 for mini)
                breathPhase = String(localized: "breath_exhale")
                SP.Haptic.soft()
                withAnimation(.easeInOut(duration: 4)) { breathScale = 0.4 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [self] in
                    guard isBreathing else { return }
                    breathCycles += 1
                    runBreathCycle()
                }
            }
        }
    }
}
