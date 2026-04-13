import SwiftUI

// MARK: - Splash Screen

// Branded launch → анимированный лого → переход к основному интерфейсу.
// Показывается 1.5 секунды при каждом холодном старте.

struct SplashScreenView: View {
    // MARK: Internal

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            // Dark background matching the app theme
            Color(red: 0.06, green: 0.06, blue: 0.10)
                .ignoresSafeArea()

            // Subtle ambient particles
            ForEach(0 ..< 8, id: \.self) { i in
                Circle()
                    .fill(
                        i.isMultiple(of: 2)
                            ? Color(red: 0.45, green: 0.40, blue: 0.95).opacity(0.08)
                            : Color(red: 0.35, green: 0.75, blue: 0.85).opacity(0.06)
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
                                    Color(red: 0.45, green: 0.40, blue: 0.95).opacity(0.3),
                                    Color(red: 0.35, green: 0.75, blue: 0.85).opacity(0.2),
                                    Color(red: 0.45, green: 0.40, blue: 0.95).opacity(0.1),
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
                            Color(red: 0.45, green: 0.40, blue: 0.95).opacity(0.15),
                            lineWidth: 1
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(ringScale * 0.95)
                        .opacity(ringOpacity * 0.7)

                    // Logo circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.40, blue: 0.95),
                                    Color(red: 0.35, green: 0.30, blue: 0.85),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Color(red: 0.45, green: 0.40, blue: 0.95).opacity(0.4), radius: 20, y: 8)

                    // Shield icon
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 6) {
                    Text("Stillō")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Точка покоя")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(textOpacity)
            }
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

            // Auto-dismiss after 1.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
}
