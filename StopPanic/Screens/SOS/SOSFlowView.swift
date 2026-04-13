import CoreHaptics
import SwiftUI

// MARK: - SOS Flow View — Premium Edition

// Полноэкранный режим помощи при панической атаке.
// Particles, glassmorphism, spring animations.

struct SOSFlowView: View {
    // MARK: Internal

    enum SOSStep: Int, CaseIterable {
        case breathing
        case grounding
        case affirmation
    }

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            SP.Colors.bg.ignoresSafeArea()

            // Particles
            ForEach(0 ..< 8, id: \.self) { i in
                FloatingParticle(
                    color: stepColor,
                    size: particleSizes[i]
                )
            }

            VStack(spacing: 0) {
                topBar
                progressDots.padding(.top, 8)

                Spacer()

                Group {
                    switch currentStep {
                    case .breathing: breathingStepView
                    case .grounding: groundingStepView
                    case .affirmation: affirmationStepView
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )

                Spacer()

                bottomAction.padding(.bottom, 40)
            }
            .padding(.horizontal, SP.Layout.padding)
        }
        .onAppear {
            startBreathing()
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
        .onDisappear { stopTimers() }
    }

    // MARK: Private

    @State
    private var currentStep: SOSStep = .breathing
    @State
    private var breathScale: CGFloat = 0.6
    @State
    private var breathPhase: String = String(localized: "breath_inhale")
    @State
    private var breathTimer: Timer?
    @State
    private var secondsElapsed: Int = 0
    @State
    private var breathingCycles: Int = 0
    @State
    private var countdownTimer: Timer?
    @State
    private var groundingStep = 0
    @State
    private var appeared = false
    @State
    private var completionScale: CGFloat = 0.3

    /// Pre-computed random sizes to avoid recalculation during render
    private let particleSizes: [CGFloat] = (0 ..< 8).map { _ in CGFloat.random(in: 4 ... 10) }

    private var timeString: String {
        let m = secondsElapsed / 60
        let s = secondsElapsed % 60
        return String(format: "%d:%02d", m, s)
    }

    private var breathHint: String {
        switch breathPhase {
        case String(localized: "breath_inhale"): String(localized: "sos.hint_inhale")
        case String(localized: "breath_hold"): String(localized: "sos.hint_hold")
        case String(localized: "breath_exhale"): String(localized: "sos.hint_exhale")
        default: ""
        }
    }

    // MARK: - Logic

    private var stepColor: Color {
        switch currentStep {
        case .breathing: SP.Colors.calm
        case .grounding: SP.Colors.accent
        case .affirmation: SP.Colors.success
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                stopTimers()
                withAnimation(SP.Anim.spring) {
                    coordinator.showSOSOverlay = false
                    coordinator.sosService.deactivateSOS()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                    Text(String(localized: "general.close"))
                        .font(SP.Typography.subheadline)
                }
                .foregroundColor(SP.Colors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(.warmGlass))
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
            }

            Spacer()

            Text(timeString)
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.top, 12)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 12) {
            ForEach(SOSStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(
                        step.rawValue <= currentStep.rawValue ? stepColor : SP.Colors.textTertiary
                    )
                    .frame(width: step == currentStep ? 32 : 12, height: 6)
                    .animation(SP.Anim.springFast, value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Breathing

    private var breathingStepView: some View {
        VStack(spacing: 24) {
            Text(String(localized: "sos.breathe_with_me"))
                .font(SP.Typography.title1)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "sos.you_are_safe_detail"))
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)

            // Breathing circle with particles
            ZStack {
                // Outer particles ring
                ForEach(0 ..< 12, id: \.self) { i in
                    Circle()
                        .fill(SP.Colors.calm.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .offset(y: -(SP.Layout.breathCircleSize / 2 + 20))
                        .rotationEffect(.degrees(Double(i) * 30))
                        .scaleEffect(breathScale)
                }

                Circle()
                    .stroke(SP.Colors.calm.opacity(0.15), lineWidth: 2)
                    .frame(width: SP.Layout.breathCircleSize + 20)
                    .scaleEffect(breathScale * 0.95)

                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [SP.Colors.calm.opacity(0.35), SP.Colors.calm.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: SP.Layout.breathCircleSize / 2
                        )
                    )
                    .frame(width: SP.Layout.breathCircleSize)
                    .scaleEffect(breathScale)
                    .blur(radius: 8)

                // Main circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [SP.Colors.calm.opacity(0.4), SP.Colors.calm.opacity(0.1)],
                            center: .center,
                            startRadius: 20,
                            endRadius: SP.Layout.breathCircleSize / 2
                        )
                    )
                    .frame(width: SP.Layout.breathCircleSize)
                    .scaleEffect(breathScale)
                    .overlay(
                        Circle()
                            .stroke(SP.Colors.calm.opacity(0.5), lineWidth: 1.5)
                            .frame(width: SP.Layout.breathCircleSize)
                            .scaleEffect(breathScale)
                    )

                VStack(spacing: 8) {
                    Text(breathPhase)
                        .font(SP.Typography.breathPhase)
                        .foregroundColor(.white)
                        .contentTransition(.opacity)

                    Text(breathHint)
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textSecondary)
                }
            }
            .padding(.vertical, 20)

            if coordinator.healthManager.heartRate > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(SP.Colors.danger)
                        .font(.system(size: 14))
                    Text("\(Int(coordinator.healthManager.heartRate)) BPM")
                        .font(SP.Typography.subheadline)
                        .foregroundColor(SP.Colors.textSecondary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(.warmGlass))
            }
        }
    }

    // MARK: - Step 2: Grounding 5-4-3-2-1

    private var groundingStepView: some View {
        let steps = [
            ("👁️", String(localized: "sos.ground_see_title"), String(localized: "sos.ground_see_sub")),
            ("✋", String(localized: "sos.ground_touch_title"), String(localized: "sos.ground_touch_sub")),
            ("👂", String(localized: "sos.ground_hear_title"), String(localized: "sos.ground_hear_sub")),
            ("👃", String(localized: "sos.ground_smell_title"), String(localized: "sos.ground_smell_sub")),
            ("👅", String(localized: "sos.ground_taste_title"), String(localized: "sos.ground_taste_sub")),
        ]

        let current = min(groundingStep, steps.count - 1)
        let (emoji, title, sub) = steps[current]

        return VStack(spacing: 28) {
            Text(String(localized: "sos.grounding"))
                .font(SP.Typography.title1)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "sos.grounding_sub"))
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)

            Spacer().frame(height: 10)

            Text(emoji)
                .font(.system(size: 64))
                .scaleEffect(appeared ? 1 : 0)
                .animation(SP.Anim.springBouncy, value: groundingStep)

            Text(title)
                .font(SP.Typography.heroTitle)
                .foregroundColor(SP.Colors.accent)
                .contentTransition(.opacity)

            Text(sub)
                .font(SP.Typography.title3)
                .foregroundColor(SP.Colors.textSecondary)

            HStack(spacing: 8) {
                ForEach(0 ..< 5, id: \.self) { i in
                    Circle()
                        .fill(i <= groundingStep ? SP.Colors.accent : SP.Colors.bgCardHover)
                        .frame(width: 12, height: 12)
                        .scaleEffect(i == groundingStep ? 1.3 : 1.0)
                        .animation(SP.Anim.springBouncy, value: groundingStep)
                }
            }
            .padding(.top, 12)

            if groundingStep < 4 {
                Button {
                    SP.Haptic.light()
                    withAnimation(SP.Anim.spring) { groundingStep += 1 }
                } label: {
                    Text(String(localized: "sos.ground_next"))
                        .spSecondaryButton()
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Step 3: Affirmation

    private var affirmationStepView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(SP.Colors.success.opacity(0.12))
                    .frame(width: 130, height: 130)
                    .scaleEffect(completionScale)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(SP.Colors.success)
                    .scaleEffect(completionScale)
                    .shadow(color: SP.Colors.success.opacity(0.4), radius: 20, y: 4)
            }
            .onAppear {
                withAnimation(SP.Anim.springBouncy) { completionScale = 1.0 }
                SP.Haptic.success()
            }

            Text(String(localized: "sos.you_did_it"))
                .font(SP.Typography.heroTitle)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "sos.affirmation_body"))
            .font(SP.Typography.body)
            .foregroundColor(SP.Colors.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)

            VStack(spacing: 12) {
                HStack {
                    Label(String(localized: "sos.duration"), systemImage: "clock")
                    Spacer()
                    Text(timeString).bold()
                }
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)

                HStack {
                    Label(String(localized: "sos.breath_cycles"), systemImage: "wind")
                    Spacer()
                    Text("\(breathingCycles)").bold()
                }
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)
            }
            .spGlassCard()

            Button {
                // Intensity based on duration: longer session = more intense episode was
                let estimatedIntensity = min(max(10 - (secondsElapsed / 60), 3), 9)
                coordinator.diaryService.addDiaryEpisode(
                    intensity: estimatedIntensity,
                    notes: "SOS session, duration: \(timeString), cycles: \(breathingCycles)"
                )
                coordinator.completedSession()
                ReviewService.shared.trackSessionCompleted()
                coordinator.showSOSOverlay = false
            } label: {
                Text(String(localized: "sos.save_and_close"))
                    .spPrimaryButton()
            }
        }
    }

    // MARK: - Bottom Action

    private var bottomAction: some View {
        Group {
            if currentStep != .affirmation {
                Button {
                    SP.Haptic.medium()
                    withAnimation(SP.Anim.spring) { advanceStep() }
                } label: {
                    HStack {
                        Text(currentStep == .breathing ? String(localized: "sos.feeling_better") : String(localized: "general.next"))
                        Image(systemName: "arrow.right")
                    }
                    .spPrimaryButton()
                }
            }
        }
    }

    private func advanceStep() {
        stopTimers()
        guard let nextRaw = SOSStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextRaw
        if nextRaw == .breathing { startBreathing() }
    }

    private func startBreathing() {
        var phase = 0
        let durations: [TimeInterval] = [4, 7, 8]
        var elapsed: TimeInterval = 0

        breathPhase = String(localized: "breath_inhale")
        withAnimation(.easeInOut(duration: 4)) { breathScale = 1.0 }

        breathTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            elapsed += 0.1
            if elapsed >= durations[phase] {
                elapsed = 0
                phase = (phase + 1) % 3
                switch phase {
                case 0:
                    breathPhase = String(localized: "breath_inhale")
                    breathingCycles += 1
                    SP.Haptic.soft()
                    withAnimation(.easeInOut(duration: 4)) { breathScale = 1.0 }
                case 1:
                    breathPhase = String(localized: "breath_hold")
                    withAnimation(.easeInOut(duration: 0.3)) { breathScale = 0.95 }
                case 2:
                    breathPhase = String(localized: "breath_exhale")
                    SP.Haptic.soft()
                    withAnimation(.easeInOut(duration: 8)) { breathScale = 0.6 }
                default: break
                }
            }
        }
        RunLoop.main.add(breathTimer!, forMode: .common)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            secondsElapsed += 1
        }
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }

    private func stopTimers() {
        breathTimer?.invalidate()
        breathTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}
