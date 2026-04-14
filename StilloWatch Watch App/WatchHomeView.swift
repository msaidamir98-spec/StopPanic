import HealthKit
import SwiftUI

// MARK: - WatchHomeView

/// Главный экран Apple Watch — пульсовый дашборд с живой анимацией
struct WatchHomeView: View {
    // MARK: Internal

    @ObservedObject
    var heartService: WatchHeartService
    @ObservedObject
    var connectivity: WatchConnectionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // MARK: - Heart Rate Hero

                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [hrColor.opacity(0.25), .clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)

                    // Gradient ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [hrColor, hrColor.opacity(0.3), hrColor],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(ringRotation))

                    // Inner glass
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)

                    Circle()
                        .fill(hrColor.opacity(glowOpacity * 0.15))
                        .frame(width: 100, height: 100)

                    // Heart rate display
                    VStack(spacing: -2) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(hrColor)
                            .scaleEffect(pulseScale)

                        Text("\(Int(heartService.currentHR))")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(value: heartService.currentHR))

                        Text(String(localized: "watch.bpm"))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .onAppear { startAnimations() }

                // MARK: - Status Badge

                statusBadge

                // MARK: - Mini Stats

                if heartService.isMonitoring, heartService.hrvValue > 0 {
                    HStack(spacing: 16) {
                        miniStat(
                            value: String(format: "%.0f", heartService.hrvValue),
                            label: "HRV",
                            icon: "waveform.path.ecg",
                            color: .cyan
                        )
                        miniStat(
                            value: String(format: "%.0f%%", heartService.irregularity * 100),
                            label: String(localized: "watch.irreg"),
                            icon: "waveform",
                            color: heartService.irregularity > 0.35 ? .red : .green
                        )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }

                // MARK: - Controls

                Button {
                    WKInterfaceDevice.current().play(.click)
                    if heartService.isMonitoring {
                        heartService.stopMonitoring()
                    } else {
                        heartService.startMonitoring()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: heartService.isMonitoring ? "stop.circle.fill" : "heart.circle.fill")
                            .font(.body)
                        Text(heartService.isMonitoring ? String(localized: "watch.stop") : String(localized: "watch.monitoring"))
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .tint(heartService.isMonitoring ? .red : .green)

                if heartService.isMonitoring {
                    Button {
                        WKInterfaceDevice.current().play(.click)
                        showAnalysis = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.body)
                            Text(String(localized: "watch.diagnosis"))
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .tint(.blue)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Connection indicator
                if connectivity.isPhoneReachable {
                    HStack(spacing: 4) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 8))
                        Text(String(localized: "watch.iphone_connected"))
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.green.opacity(0.7))
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Stillō")
        .sheet(isPresented: $showAnalysis) {
            WatchAnalysisResultView(heartService: heartService)
        }
        .animation(.easeInOut(duration: 0.4), value: heartService.isMonitoring)
        .animation(.easeInOut(duration: 0.4), value: heartService.diagnosis)
    }

    // MARK: Private

    @State
    private var showAnalysis = false
    @State
    private var pulseScale: CGFloat = 1.0
    @State
    private var ringRotation: Double = 0
    @State
    private var glowOpacity: Double = 0.3

    private var hrColor: Color {
        switch heartService.diagnosis {
        case .normal: .green
        case .panicAttack: .yellow
        case .possibleCardiac: .red
        case .inconclusive: .cyan
        }
    }

    // MARK: - Components

    @ViewBuilder
    private var statusBadge: some View {
        let status = heartService.currentStatus
        HStack(spacing: 5) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
                .shadow(color: status.color, radius: 3)

            Text(status.text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(status.color.opacity(0.3), lineWidth: 0.5)
        )
    }

    private func miniStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
            glowOpacity = 0.7
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }
}

// MARK: - WatchAnalysisResultView

/// Результат анализа паттернов пульса — premium карточка
struct WatchAnalysisResultView: View {
    // MARK: Internal

    @ObservedObject
    var heartService: WatchHeartService

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Diagnosis icon
                ZStack {
                    Circle()
                        .fill(heartService.diagnosisColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: heartService.diagnosisIcon)
                        .font(.title2)
                        .foregroundStyle(heartService.diagnosisColor)
                        .symbolEffect(.pulse, options: .repeating)
                }

                Text(heartService.diagnosisTitle)
                    .font(.system(.headline, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(heartService.diagnosisDetail)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)

                // Metrics row
                HStack(spacing: 0) {
                    metricCard(
                        value: "\(Int(heartService.currentHR))",
                        label: String(localized: "watch.hr_label"),
                        color: .red
                    )

                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 0.5, height: 30)

                    metricCard(
                        value: String(format: "%.0f", heartService.hrvValue),
                        label: String(localized: "watch.hrv_ms"),
                        color: .cyan
                    )

                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 0.5, height: 30)

                    metricCard(
                        value: String(format: "%.0f%%", heartService.irregularity * 100),
                        label: String(localized: "watch.irreg"),
                        color: heartService.irregularity > 0.35 ? .red : .green
                    )
                }
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                if heartService.suggestMedicalConsult {
                    Button(role: .destructive) {
                        // Emergency
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                            Text(String(localized: "watch.call_112"))
                                .font(.system(.caption, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .tint(.red)
                }

                Button {
                    dismiss()
                } label: {
                    Text(String(localized: "watch.close"))
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .tint(.gray.opacity(0.5))
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss

    private func metricCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        WatchHomeView(heartService: WatchHeartService(), connectivity: WatchConnectionManager.shared)
    }
}
