import HealthKit
import SwiftUI

// MARK: - HealthKitSettingsView

/// Экран настройки Apple Health — статус, подключение, описание данных.
struct HealthKitSettingsView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.danger, secondaryColor: SP.Colors.accent)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    statusCard
                    dataExplanationCard
                    privacyCard
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkAvailability()
            withAnimation(SP.Anim.spring) { appear = true }
        }
    }

    // MARK: Private

    @State
    private var isAvailable = false
    @State
    private var isConnected = false
    @State
    private var appear = false
    @State
    private var isConnecting = false

    private var statusTitle: String {
        if !isAvailable {
            return String(localized: "health.unavailable")
        }
        return isConnected ? String(localized: "health.connected") : String(localized: "health.not_connected")
    }

    private var statusSubtitle: String {
        if !isAvailable {
            return String(localized: "health.unavailable_body")
        }
        return isConnected
            ? String(localized: "health.connected_body")
            : String(localized: "health.not_connected_body")
    }

    private var statusCard: some View {
        VStack(spacing: 14) {
            ZStack {
                // Pulse animation for heart
                if isConnected {
                    Circle()
                        .fill(SP.Colors.danger.opacity(0.1))
                        .frame(width: 70, height: 70)
                        .modifier(GlowPulse(color: SP.Colors.danger, radius: 0.3))
                }

                Circle()
                    .fill(isConnected ? SP.Colors.danger.opacity(0.15) : SP.Colors.textTertiary.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: isConnected ? "heart.fill" : "heart.slash")
                    .font(.system(size: 24))
                    .foregroundColor(isConnected ? SP.Colors.danger : SP.Colors.textTertiary)
                    .symbolEffect(.pulse, isActive: isConnecting)
            }

            Text(statusTitle)
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            Text(statusSubtitle)
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
                .multilineTextAlignment(.center)

            if !isAvailable {
                // HealthKit not available (simulator, iPad, etc.)
                Label(String(localized: "health.unavailable_device"), systemImage: "exclamationmark.triangle.fill")
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.warmth)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(SP.Colors.warmth.opacity(0.1))
                    )
            } else if !isConnected {
                Button {
                    connectHealthKit()
                } label: {
                    HStack(spacing: 8) {
                        if isConnecting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(String(localized: "health.connect"))
                    }
                    .spPrimaryButton()
                }
                .disabled(isConnecting)
                .padding(.top, 4)
            } else {
                Label(String(localized: "health.connected_label"), systemImage: "checkmark.circle.fill")
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.success)
            }
        }
        .frame(maxWidth: .infinity)
        .spGlassCard()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
    }

    private var dataExplanationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: "health.data_title"))
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            dataRow(
                icon: "heart.fill",
                title: String(localized: "health.data_pulse"),
                description: String(localized: "health.data_pulse_desc"),
                color: SP.Colors.danger
            )

            dataRow(
                icon: "waveform.path.ecg",
                title: String(localized: "health.data_hrv"),
                description: String(localized: "health.data_hrv_desc"),
                color: SP.Colors.accent
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spGlassCard()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.1), value: appear)
    }

    private var privacyCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 28))
                .foregroundColor(SP.Colors.accent)

            Text(String(localized: "health.privacy_title"))
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "health.privacy_body"))
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .spGlassCard()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.2), value: appear)
    }

    private func dataRow(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textPrimary)
                Text(description)
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }
        }
    }

    private func checkAvailability() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
        isConnected = coordinator.healthManager.isAuthorized
    }

    private func connectHealthKit() {
        isConnecting = true
        coordinator.healthManager.requestPermissions()

        // Re-check after a delay (system dialog)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isConnected = coordinator.healthManager.isAuthorized
            isConnecting = false
            if isConnected {
                SP.Haptic.success()
            }
        }
    }
}
