import SwiftUI
import WatchKit

// MARK: - Premium Watch SOS View

/// Экстренная кнопка SOS — полноэкранный экран с драматичным отсчётом
struct WatchSOSView: View {
    // MARK: Internal

    @ObservedObject
    var connectivity: WatchConnectionManager

    var body: some View {
        ZStack {
            // Background pulse when counting down
            if isCountingDown {
                Color.red.opacity(0.08)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isCountingDown)
            }

            VStack(spacing: 10) {
                if sosTriggered {
                    sosActiveView
                } else if isCountingDown {
                    countdownView
                } else {
                    mainSOSButton
                }
            }
        }
        .navigationTitle("SOS")
    }

    // MARK: Private

    @State
    private var isCountingDown = false
    @State
    private var countdown: Int = 5
    @State
    private var sosTriggered = false
    @State
    private var pulseScale: CGFloat = 1.0
    @State
    private var rippleScale: CGFloat = 0.8
    @State
    private var rippleOpacity: Double = 0.5
    @State
    private var shakeOffset: CGFloat = 0

    // MARK: - SOS Active

    @ViewBuilder
    private var sosActiveView: some View {
        Spacer()

        ZStack {
            // Ripple waves
            Circle()
                .stroke(.red.opacity(0.2), lineWidth: 2)
                .frame(width: 100, height: 100)
                .scaleEffect(rippleScale)
                .opacity(rippleOpacity)

            Circle()
                .fill(.red.opacity(0.15))
                .frame(width: 70, height: 70)

            Image(systemName: "phone.fill.arrow.up.right")
                .font(.title2)
                .foregroundStyle(.red)
                .symbolEffect(.pulse, options: .repeating)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                rippleScale = 2.0
                rippleOpacity = 0
            }
        }

        Text(String(localized: "watch.sos_sent"))
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.red)

        Text(String(localized: "watch.sos_iphone_notify"))
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.secondary)

        if connectivity.isPhoneReachable {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                Text(String(localized: "watch.sos_delivered"))
                    .font(.system(size: 10))
            }
            .foregroundStyle(.green)
        }

        Spacer()

        Button {
            WKInterfaceDevice.current().play(.click)
            sosTriggered = false
            rippleScale = 0.8
            rippleOpacity = 0.5
        } label: {
            Text(String(localized: "watch.sos_cancel"))
                .font(.system(.caption, design: .rounded, weight: .medium))
                .frame(maxWidth: .infinity)
        }
        .tint(.gray.opacity(0.5))
    }

    // MARK: - Countdown

    @ViewBuilder
    private var countdownView: some View {
        Spacer()

        Text(String(localized: "watch.sos_countdown"))
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.red.opacity(0.7))

        ZStack {
            // Background pulse
            Circle()
                .fill(.red.opacity(0.1))
                .frame(width: 90, height: 90)
                .scaleEffect(pulseScale)

            Circle()
                .stroke(.red.opacity(0.3), lineWidth: 3)
                .frame(width: 80, height: 80)

            Text("\(countdown)")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(.red)
                .contentTransition(.numericText(value: Double(countdown)))
                .offset(x: shakeOffset)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }

        Spacer()

        Button {
            WKInterfaceDevice.current().play(.stop)
            cancelCountdown()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                Text(String(localized: "watch.sos_cancel_short"))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .tint(.gray)
    }

    // MARK: - Main SOS Button

    @ViewBuilder
    private var mainSOSButton: some View {
        Spacer()

        Text(String(localized: "watch.sos_emergency"))
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(.secondary)

        Button {
            startCountdown()
        } label: {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.red.opacity(0.3), .red.opacity(0.05)],
                            center: .center,
                            startRadius: 25,
                            endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 85, height: 85)
                    .shadow(color: .red.opacity(0.4), radius: 8, y: 2)

                // Inner highlight
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 85, height: 85)
                    .mask(
                        LinearGradient(
                            colors: [.white, .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                VStack(spacing: 1) {
                    Image(systemName: "sos")
                        .font(.system(size: 20, weight: .bold))
                    Text("SOS")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)

        Text(String(localized: "watch.sos_send"))
            .font(.system(size: 9))
            .foregroundStyle(.secondary)

        Spacer()
    }

    // MARK: - Logic

    private func startCountdown() {
        isCountingDown = true
        countdown = 5
        pulseScale = 1.0
        WKInterfaceDevice.current().play(.notification)
        tickDown()
    }

    private func cancelCountdown() {
        isCountingDown = false
        countdown = 5
        pulseScale = 1.0
    }

    private func tickDown() {
        guard isCountingDown, countdown > 0 else {
            if isCountingDown {
                triggerSOS()
            }
            return
        }

        // Shake effect
        withAnimation(.spring(duration: 0.1)) {
            shakeOffset = 4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(duration: 0.1)) {
                shakeOffset = -4
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(duration: 0.1)) {
                shakeOffset = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            countdown -= 1
            WKInterfaceDevice.current().play(.click)
            tickDown()
        }
    }

    private func triggerSOS() {
        isCountingDown = false
        sosTriggered = true
        WKInterfaceDevice.current().play(.failure)
        connectivity.triggerSOSOnPhone()
    }
}

#Preview {
    WatchSOSView(connectivity: WatchConnectionManager.shared)
}
