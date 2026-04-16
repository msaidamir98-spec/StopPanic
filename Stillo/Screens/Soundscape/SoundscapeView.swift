import SwiftUI

// MARK: - SoundscapeView

/// Премиальный экран выбора фонового звука.
/// Каждый трек — научно обоснован для снижения тревоги.
/// Интерфейс: горизонтальный карусельный выбор + volume slider + play/stop.

struct SoundscapeView: View {
    @Environment(AppCoordinator.self) var coordinator

    var body: some View {
        let ambient = coordinator.ambientSound

        ZStack {
            AmbientBackground(
                primaryColor: trackColor(ambient.selectedTrack),
                secondaryColor: SP.Colors.accent
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 16)

                    // MARK: - Now Playing Visualization
                    nowPlayingSection(ambient)

                    // MARK: - Track Selector
                    trackSelector(ambient)

                    // MARK: - Play / Stop
                    playButton(ambient)

                    // MARK: - Volume Control
                    volumeControl(ambient)

                    // MARK: - Science Info
                    scienceCard(ambient)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, SP.Layout.padding)
            }
            .background(ScrollBounceDisabler())
        }
        .navigationTitle(String(localized: "soundscape.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    // MARK: - Private

    @State private var appeared = false

    // MARK: - Now Playing Visualization

    private func nowPlayingSection(_ ambient: AmbientSoundService) -> some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(trackColor(ambient.selectedTrack).opacity(0.06))
                    .frame(width: 180, height: 180)
                    .scaleEffect(ambient.isPlaying ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: ambient.isPlaying)

                // Inner pulse ring
                Circle()
                    .fill(trackColor(ambient.selectedTrack).opacity(0.12))
                    .frame(width: 130, height: 130)
                    .scaleEffect(ambient.isPlaying ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.3), value: ambient.isPlaying)

                // Icon
                Image(systemName: ambient.selectedTrack.icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [trackColor(ambient.selectedTrack), trackColor(ambient.selectedTrack).opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.variableColor.iterative, isActive: ambient.isPlaying)
            }

            VStack(spacing: 6) {
                Text(String(localized: String.LocalizationValue(ambient.selectedTrack.nameKey)))
                    .font(SP.Typography.title2)
                    .foregroundColor(SP.Colors.textPrimary)

                Text(String(localized: String.LocalizationValue(ambient.selectedTrack.descriptionKey)))
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(SP.Anim.spring.delay(0.05), value: appeared)
    }

    // MARK: - Track Selector

    private func trackSelector(_ ambient: AmbientSoundService) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "soundscape.choose_sound"))
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            ForEach(ambient.availableTracks) { track in
                trackRow(track, ambient: ambient)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .animation(SP.Anim.spring.delay(0.1), value: appeared)
    }

    private func trackRow(_ track: AmbientSoundService.SoundTrack, ambient: AmbientSoundService) -> some View {
        Button {
            SP.Haptic.selectionChanged()
            // Load per-track volume when switching
            let vKey = "ambient_volume_\(track.rawValue)"
            let saved = UserDefaults.standard.double(forKey: vKey)
            if saved > 0 { ambient.volume = saved }
            ambient.selectedTrack = track
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(trackColor(track).opacity(ambient.selectedTrack == track ? 0.2 : 0.08))
                        .frame(width: 44, height: 44)
                    Image(systemName: track.icon)
                        .font(.system(size: 18))
                        .foregroundColor(trackColor(track))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: String.LocalizationValue(track.nameKey)))
                        .font(SP.Typography.subheadline)
                        .foregroundColor(SP.Colors.textPrimary)
                    Text(String(localized: String.LocalizationValue(track.descriptionKey)))
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                if ambient.selectedTrack == track && ambient.isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(trackColor(track))
                        .symbolEffect(.variableColor.iterative, isActive: true)
                } else if ambient.selectedTrack == track {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SP.Colors.heroGradient)
                } else {
                    Circle()
                        .stroke(SP.Colors.textTertiary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: SP.Layout.cornerSmall, style: .continuous)
                    .fill(ambient.selectedTrack == track
                        ? trackColor(track).opacity(0.06)
                        : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Play / Stop

    private func playButton(_ ambient: AmbientSoundService) -> some View {
        Button {
            SP.Haptic.selectionChanged()
            ambient.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: ambient.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 18))
                    .contentTransition(.symbolEffect(.replace))
                Text(ambient.isPlaying
                    ? String(localized: "soundscape.stop")
                    : String(localized: "soundscape.play"))
                    .font(SP.Typography.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ambient.isPlaying
                    ? AnyShapeStyle(SP.Colors.danger.opacity(0.85))
                    : AnyShapeStyle(SP.Colors.heroGradient)
            )
            .clipShape(RoundedRectangle(cornerRadius: SP.Layout.cornerMedium))
        }
        .disabled(!ambient.isFileAvailable)
        .opacity(ambient.isFileAvailable ? 1 : 0.5)
        .opacity(appeared ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.15), value: appeared)
    }

    // MARK: - Volume

    private func volumeControl(_ ambient: AmbientSoundService) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(SP.Colors.textTertiary)
                    .font(.system(size: 14))
                Slider(value: Binding(
                    get: { ambient.volume },
                    set: { ambient.volume = $0 }
                ), in: 0...1)
                .tint(trackColor(ambient.selectedTrack))
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(SP.Colors.textTertiary)
                    .font(.system(size: 14))
            }

            Text("\(Int(ambient.volume * 100))%")
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .opacity(appeared ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.2), value: appeared)
    }

    // MARK: - Science Card

    private func scienceCard(_ ambient: AmbientSoundService) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile.fill")
                    .foregroundColor(SP.Colors.accent)
                Text(String(localized: "soundscape.science_title"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }

            Text(String(localized: "soundscape.science_body"))
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textSecondary)
                .lineSpacing(3)
        }
        .spGlassCard()
        .opacity(appeared ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.25), value: appeared)
    }

    // MARK: - Helpers

    private func trackColor(_ track: AmbientSoundService.SoundTrack) -> Color {
        switch track {
        case .brownNoise:   SP.Colors.warmth
        case .pinkNoise:    SP.Colors.accent
        case .gentleRain:   SP.Colors.calm
        case .oceanWaves:   Color.teal
        case .forestStream: SP.Colors.success
        }
    }
}
