import SwiftUI

// MARK: - Beautiful Breathing Session

// Визуально потрясающая сессия дыхания с анимацией и хаптиками.
// Поддерживает 4 техники: 4-7-8, Квадратное, 2x, Резонансное.
// ✨ Premium treatment: частицы, glow ring, стекло, shimmer

struct BreathingSessionView: View {
    // MARK: Internal

    enum BreathPhase: String {
        case ready = "Готов?"
        case inhale = "Вдох"
        case hold = "Задержка"
        case exhale = "Выдох"
        case holdAfter = "Пауза"
        case complete = "Готово!"
    }

    let technique: BreathingTechnique

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            // Ambient background with floating particles
            AmbientBackground(primaryColor: technique.color, secondaryColor: SP.Colors.calm)

            VStack(spacing: 0) {
                topBar
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : -20)

                Spacer()

                breathingVisualization
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.8)

                Spacer()

                statsRow
                    .padding(.bottom, 20)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 30)

                controlButton
                    .padding(.bottom, 40)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
            }
            .padding(.horizontal, SP.Layout.padding)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appear = true
            }
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                particleRotation = 360
            }
        }
        .onDisappear {
            stopSession()
        }
        .navigationBarHidden(true)
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var isActive = false
    @State
    private var breathScale: CGFloat = 0.5
    @State
    private var breathOpacity: Double = 0.3
    @State
    private var phase: BreathPhase = .ready
    @State
    private var phaseText: String = "Готов?"
    @State
    private var cycleCount = 0
    @State
    private var totalSeconds = 0
    @State
    private var breathTimer: Timer?
    @State
    private var sessionTimer: Timer?
    @State
    private var ringProgress: CGFloat = 0
    @State
    private var appear = false
    @State
    private var particleRotation: Double = 0

    /// Pre-computed random particle sizes to avoid recalculation during render
    private let particleSizes: [(w: CGFloat, h: CGFloat)] = (0 ..< 16).map { _ in
        let s = CGFloat(Int.random(in: 3 ... 6))
        return (w: s, h: s)
    }

    private var formattedTime: String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private var phaseHint: String {
        switch phase {
        case .inhale: "через нос 🫁"
        case .hold: "спокойно 🧘"
        case .exhale: "через рот 💨"
        case .holdAfter: "расслабься"
        default: ""
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                stopSession()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SP.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            }

            Spacer()

            VStack(spacing: 2) {
                Text(technique.name)
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Text(technique.subtitle)
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }

            Spacer()

            Text(formattedTime)
                .font(SP.Typography.caption)
                .monospacedDigit()
                .foregroundColor(SP.Colors.textTertiary)
                .frame(width: 36)
        }
        .padding(.top, 8)
    }

    // MARK: - Breathing Visualization

    private var breathingVisualization: some View {
        ZStack {
            // Orbiting particles (16 dots)
            ForEach(0 ..< 16, id: \.self) { i in
                Circle()
                    .fill(technique.color.opacity(0.4))
                    .frame(width: particleSizes[i].w, height: particleSizes[i].h)
                    .blur(radius: 1)
                    .offset(y: -140)
                    .rotationEffect(.degrees(Double(i) * 22.5 + particleRotation))
            }

            // Outer progress ring
            Circle()
                .stroke(technique.color.opacity(0.1), lineWidth: 3)
                .frame(width: 280, height: 280)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            technique.color.opacity(0.3), technique.color,
                            technique.color.opacity(0.3),
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))

            // Glow layer
            Circle()
                .fill(technique.color.opacity(breathOpacity * 0.3))
                .frame(width: 240, height: 240)
                .scaleEffect(breathScale * 1.15)
                .blur(radius: 40)

            // Main breathing circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            technique.color.opacity(breathOpacity * 0.9),
                            technique.color.opacity(breathOpacity * 0.3),
                            technique.color.opacity(breathOpacity * 0.05),
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 110
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(breathScale)

            // Inner ring with glass feel
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                .frame(width: 200, height: 200)
                .scaleEffect(breathScale)

            // Center dot
            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: 6, height: 6)

            // Phase text
            VStack(spacing: 8) {
                Text(phaseText)
                    .font(SP.Typography.breathPhase)
                    .foregroundColor(.white)
                    .contentTransition(.opacity)

                if isActive, phase != .ready {
                    Text(phaseHint)
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textSecondary)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 14) {
            statItem(icon: "repeat", value: "\(cycleCount)", label: "циклов")
            statItem(icon: "clock", value: formattedTime, label: "время")
            statItem(
                icon: "bolt.heart", value: "\(Int(coordinator.healthManager.heartRate))",
                label: "BPM"
            )
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
    }

    // MARK: - Control

    private var controlButton: some View {
        Button {
            SP.Haptic.medium()
            if isActive {
                stopSession()
            } else {
                startSession()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isActive ? "stop.fill" : "play.fill")
                    .contentTransition(.symbolEffect(.replace))
                Text(isActive ? "Остановить" : "Начать")
            }
            .font(SP.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: SP.Layout.cornerSmall)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: SP.Layout.cornerSmall)
                                    .fill(SP.Colors.danger.opacity(0.3))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: SP.Layout.cornerSmall)
                            .fill(SP.Colors.heroGradient)
                            .shadow(color: SP.Shadows.glow, radius: 16, y: 6)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: SP.Layout.cornerSmall))
        }
        .buttonStyle(PremiumButtonStyle())
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(technique.color)
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

    // MARK: - Session Logic

    private func startSession() {
        isActive = true
        cycleCount = 0
        totalSeconds = 0
        runBreathCycle()

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            totalSeconds += 1
        }
    }

    private func runBreathCycle() {
        guard isActive else { return }

        let totalDuration = technique.totalCycleDuration
        var elapsed: TimeInterval = 0
        var currentPhase = 0
        let phases: [(BreathPhase, TimeInterval)] = {
            var p: [(BreathPhase, TimeInterval)] = []
            if technique.inhale > 0 { p.append((.inhale, technique.inhale)) }
            if technique.hold > 0 { p.append((.hold, technique.hold)) }
            if technique.exhale > 0 { p.append((.exhale, technique.exhale)) }
            if technique.holdAfter > 0 { p.append((.holdAfter, technique.holdAfter)) }
            return p
        }()

        guard !phases.isEmpty else { return }

        setPhase(phases[0].0, duration: phases[0].1)

        breathTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            guard isActive else { return }
            elapsed += 0.1

            ringProgress = CGFloat(elapsed / totalDuration)

            var phaseEnd: TimeInterval = 0
            for i in 0 ... currentPhase {
                phaseEnd += phases[i].1
            }

            if elapsed >= phaseEnd, currentPhase + 1 < phases.count {
                currentPhase += 1
                setPhase(phases[currentPhase].0, duration: phases[currentPhase].1)
            }

            if elapsed >= totalDuration {
                elapsed = 0
                currentPhase = 0
                cycleCount += 1
                ringProgress = 0
                SP.Haptic.success()
                if isActive {
                    setPhase(phases[0].0, duration: phases[0].1)
                }
            }
        }
    }

    private func setPhase(_ p: BreathPhase, duration: TimeInterval) {
        withAnimation(SP.Anim.springSnappy) {
            phase = p
            phaseText = p.rawValue
        }
        SP.Haptic.soft()

        withAnimation(.easeInOut(duration: duration)) {
            switch p {
            case .inhale:
                breathScale = 1.0
                breathOpacity = 0.7
            case .hold:
                breathScale = 0.95
                breathOpacity = 0.6
            case .exhale:
                breathScale = 0.5
                breathOpacity = 0.3
            case .holdAfter:
                breathScale = 0.5
                breathOpacity = 0.25
            default: break
            }
        }
    }

    private func stopSession() {
        isActive = false
        breathTimer?.invalidate()
        breathTimer = nil
        sessionTimer?.invalidate()
        sessionTimer = nil

        if cycleCount > 0 {
            coordinator.totalBreathingMinutes += max(totalSeconds / 60, 1)
            coordinator.completedSession()
            ReviewService.shared.trackSessionCompleted()
        }

        withAnimation(SP.Anim.spring) {
            phase = .complete
            phaseText = cycleCount > 0 ? "Отлично! 🎉" : "Готов?"
        }
    }
}
