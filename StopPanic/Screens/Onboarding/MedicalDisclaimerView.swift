import SwiftUI

// MARK: - Medical Disclaimer View

/// Принудительный полноэкранный дисклеймер при первом запуске.
/// Показывается ДО онбординга. Пользователь ОБЯЗАН принять, чтобы продолжить.
/// Guideline 1.4.1 (Physical Harm) + 1.4.3 (Health Services)

struct MedicalDisclaimerView: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var appeared = false
    @State private var scrolledToBottom = false
    @State private var accepted = false

    var body: some View {
        ZStack {
            SP.Colors.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [SP.Colors.calm, SP.Colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)

                    Text(String(localized: "disclaimer.title"))
                        .font(SP.Typography.heroTitle)
                        .foregroundColor(SP.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                // Scrollable content
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 20) {
                        disclaimerBlock(
                            icon: "stethoscope",
                            color: .orange,
                            title: String(localized: "disclaimer.not_medical_title"),
                            body: String(localized: "disclaimer.not_medical_body")
                        )

                        disclaimerBlock(
                            icon: "exclamationmark.triangle.fill",
                            color: SP.Colors.danger,
                            title: String(localized: "disclaimer.emergency_title"),
                            body: String(localized: "disclaimer.emergency_body")
                        )

                        disclaimerBlock(
                            icon: "waveform.path.ecg",
                            color: SP.Colors.calm,
                            title: String(localized: "disclaimer.healthkit_title"),
                            body: String(localized: "disclaimer.healthkit_body")
                        )

                        disclaimerBlock(
                            icon: "person.fill.checkmark",
                            color: SP.Colors.success,
                            title: String(localized: "disclaimer.intended_use_title"),
                            body: String(localized: "disclaimer.intended_use_body")
                        )

                        // Scroll bottom detector
                        Color.clear.frame(height: 1)
                            .onAppear { scrolledToBottom = true }
                    }
                    .padding(.horizontal, SP.Layout.padding)
                    .padding(.bottom, 20)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)

                // Accept button
                VStack(spacing: 12) {
                    Button {
                        SP.Haptic.success()
                        withAnimation(SP.Anim.spring) {
                            coordinator.hasAcceptedDisclaimer = true
                        }
                    } label: {
                        Text(String(localized: "disclaimer.accept"))
                            .spPrimaryButton()
                    }
                    .disabled(!scrolledToBottom)
                    .opacity(scrolledToBottom ? 1 : 0.4)

                    if !scrolledToBottom {
                        Text(String(localized: "disclaimer.scroll_hint"))
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.bottom, 40)
                .padding(.top, 12)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { appeared = true }
        }
    }

    // MARK: - Disclaimer Block

    private func disclaimerBlock(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)

                Text(body)
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: SP.Layout.cornerMedium, style: .continuous)
                .fill(SP.Colors.bgCard.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: SP.Layout.cornerMedium, style: .continuous)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
