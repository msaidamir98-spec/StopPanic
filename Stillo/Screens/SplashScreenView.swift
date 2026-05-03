import SwiftUI

// MARK: - Splash Screen

// Branded launch → анимированный лого → переход к основному интерфейсу.
// Показывается 1.5 секунды при каждом холодном старте.

struct SplashScreenView: View {
    // MARK: Internal

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            // Theme-aware background
            SP.Colors.bg
                .ignoresSafeArea()

            // Subtle ambient particles
            ForEach(0 ..< 8, id: \.self) { i in
                Circle()
                    .fill(
                        i.isMultiple(of: 2)
                            ? SP.Colors.accent.opacity(0.08)
                            : SP.Colors.calm.opacity(0.06)
                    )
                    .frame(width: CGFloat(30 + i * 10), height: CGFloat(30 + i * 10))
                    .offset(
                        x: CGFloat([-80, 100, -60, 120, -110, 90, -40, 70][i]),
                        y: CGFloat([-120, -80, 60, 100, -40, 140, -150, 30][i])
                    )
                    .blur(radius: 20)
                    .opacity(particlesVisible ? 1 : 0)
                    .animation(.easeOut(duration: 1.0).delay(Double(i) * 0.05), value: particlesVisible)
            }

            VStack(spacing: 20) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    SP.Colors.accent.opacity(0.3),
                                    SP.Colors.calm.opacity(0.2),
                                    SP.Colors.accent.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Inner ring
                    Circle()
                        .stroke(
                            SP.Colors.accent.opacity(0.15),
                            lineWidth: 1
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringScale * 0.95)
                        .opacity(ringOpacity * 0.7)

                    // Logo circle
                    Circle()
                        .fill(SP.Colors.heroGradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: SP.Colors.accent.opacity(0.4), radius: 20, y: 8)

                    // Shield icon
                    Image(systemName: "hand.raised.fill")
                        .font(.system(.title2).weight(.bold))
                        .foregroundColor(SP.Colors.textOnAccent)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 6) {
                    Text("Stillō")
                        .font(.system(.title, design: .rounded).weight(.heavy))
                        .foregroundColor(SP.Colors.textPrimary)

                    Text(String(localized: "splash.tagline"))
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(SP.Colors.textTertiary)
                }
                .opacity(textOpacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap-to-skip — пользователь в панике не должен ждать.
            dismiss()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.15)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                particlesVisible = true
            }

            // Auto-dismiss через detached-таск. Раньше использовался
            // `DispatchQueue.main.asyncAfter`, который вис, если main
            // thread занят Core Data migration или iCloud entitlement
            // probe (см. PersistenceController). Detached-приоритет
            // userInitiated отделяет таймер от main runloop.
            Task.detached(priority: .userInitiated) {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }

    // MARK: Private

    @State
    private var logoScale: CGFloat = 0.5
    @State
    private var logoOpacity: Double = 0
    @State
    private var textOpacity: Double = 0
    @State
    private var ringScale: CGFloat = 0.3
    @State
    private var ringOpacity: Double = 0
    @State
    private var particlesVisible = false
    @State
    private var didDismiss = false

    private func dismiss() {
        guard !didDismiss else { return }
        didDismiss = true
        withAnimation(.easeIn(duration: 0.3)) {
            logoOpacity = 0
            textOpacity = 0
            ringOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onFinished()
        }
    }
}
