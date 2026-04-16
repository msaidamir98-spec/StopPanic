import SwiftUI

// MARK: - SoundscapeView

/// Экран управления фоновым звуком (коричневый шум).
/// Минимальный, надёжный UI: кнопка play/stop + ползунок громкости.

struct SoundscapeView: View {
    @Environment(AppCoordinator.self) var coordinator

    var body: some View {
        

        ZStack {
            AmbientBackground(primaryColor: SP.Colors.calm, secondaryColor: SP.Colors.accent)

            VStack(spacing: 32) {
                Spacer()

                // MARK: - Icon + Title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(SP.Colors.calm.opacity(0.15))
                            .frame(width: 120, height: 120)

                        Circle()
                            .fill(SP.Colors.calm.opacity(0.08))
                            .frame(width: 160, height: 160)
                            .scaleEffect(coordinator.ambientSound.isPlaying ? 1.15 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: coordinator.ambientSound.isPlaying)

                        Image(systemName: coordinator.ambientSound.isPlaying ? "waveform" : "waveform.badge.minus")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(SP.Colors.heroGradient)
                            .symbolEffect(.variableColor.iterative, isActive: coordinator.ambientSound.isPlaying)
                    }

                    VStack(spacing: 6) {
                        Text(String(localized: "soundscape.brown_noise_title"))
                            .font(SP.Typography.title2)
                            .foregroundColor(SP.Colors.textPrimary)

                        Text(String(localized: "soundscape.brown_noise_subtitle"))
                            .font(SP.Typography.callout)
                            .foregroundColor(SP.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }

                // MARK: - Play / Stop Button
                Button {
                    SP.Haptic.selectionChanged()
                    coordinator.ambientSound.toggle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: coordinator.ambientSound.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 18))
                        Text(coordinator.ambientSound.isPlaying
                             ? String(localized: "soundscape.stop")
                             : String(localized: "soundscape.play"))
                            .font(SP.Typography.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        coordinator.ambientSound.isPlaying
                            ? AnyShapeStyle(SP.Colors.danger.opacity(0.85))
                            : AnyShapeStyle(SP.Colors.heroGradient)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: SP.Layout.cornerMedium))
                }
                .disabled(!coordinator.ambientSound.isFileAvailable)
                .opacity(coordinator.ambientSound.isFileAvailable ? 1 : 0.5)

                // MARK: - Volume Slider
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(SP.Colors.textTertiary)
                            .font(.system(size: 14))
                        Slider(value: Binding(
                            get: { coordinator.ambientSound.volume },
                            set: { coordinator.ambientSound.volume = $0 }
                        ), in: 0...1)
                        .tint(SP.Colors.accent)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(SP.Colors.textTertiary)
                            .font(.system(size: 14))
                    }

                    Text("\(Int(coordinator.ambientSound.volume * 100))%")
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                }
                .spGlassCard(cornerRadius: SP.Layout.cornerMedium)

                // MARK: - File missing warning
                if !coordinator.ambientSound.isFileAvailable {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(SP.Colors.warning)
                        Text(String(localized: "soundscape.file_missing"))
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.warning)
                    }
                    .padding(12)
                    .background(SP.Colors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, SP.Layout.padding)
        }
        .navigationTitle(String(localized: "soundscape.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
