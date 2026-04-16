import SwiftUI

// MARK: - SoundscapeView

/// Экран выбора фонового звука.
/// Пользователь прослушивает треки и выбирает "свой" — он автозапустится при SOS.

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
                VStack(spacing: 24) {
                    Spacer(minLength: 16)

                    // Header
                    headerSection(ambient)

                    // SOS hint
                    sosHintCard

                    // Track list with preview
                    trackListSection(ambient)

                    // Play / Stop continuous
                    playButton(ambient)

                    // Volume
                    volumeControl(ambient)

                    // Science card
                    scienceCard

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, SP.Layout.padding)
            }
            .background(ScrollBounceDisabler())
        }
        .navigationTitle(String(localized: "soundscape.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { ambient.stopPreview() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    @State private var appeared = false

    // MARK: - Header

    private func headerSection(_ ambient: AmbientSoundService) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(trackColor(ambient.selectedTrack).opacity(0.06))
                    .frame(width: 160, height: 160)
                    .scaleEffect(ambient.isPlaying ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: ambient.isPlaying)

                Circle()
                    .fill(trackColor(ambient.selectedTrack).opacity(0.12))
                    .frame(width: 110, height: 110)
                    .scaleEffect(ambient.isPlaying ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.3), value: ambient.isPlaying)

                Image(systemName: ambient.selectedTrack.icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [trackColor(ambient.selectedTrack), trackColor(ambient.selectedTrack).opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.variableColor.iterative, isActive: ambient.isPlaying)
            }

            VStack(spacing: 4) {
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

    // MARK: - SOS Hint

    private var sosHintCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.heart.fill")
                .foregroundColor(SP.Colors.danger)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "soundscape.sos_hint_title"))
                    .font(SP.Typography.subheadline)
                    .foregroundColor(SP.Colors.textPrimary)
                Text(String(localized: "soundscape.sos_hint_body"))
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textSecondary)
            }
            Spacer()
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
        .opacity(appeared ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.08), value: appeared)
    }

    // MARK: - Track List

    private func trackListSection(_ ambient: AmbientSoundService) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "soundscape.choose_sound"))
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            // Show ALL tracks — even those without files yet
            ForEach(AmbientSoundService.SoundTrack.allCases) { track in
                trackRow(track, ambient: ambient)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .animation(SP.Anim.spring.delay(0.1), value: appeared)
    }

    private func trackRow(_ track: AmbientSoundService.SoundTrack, ambient: AmbientSoundService) -> some View {
        let isAvailable = ambient.availableTracks.contains(track)
        let isSelected = ambient.selectedTrack == track
        let isPreviewing = ambient.previewingTrack == track

        return HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(trackColor(track).opacity(isSelected ? 0.2 : 0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: track.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isAvailable ? trackColor(track) : SP.Colors.textTertiary)
            }

            // Name + desc
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: String.LocalizationValue(track.nameKey)))
                    .font(SP.Typography.subheadline)
                    .foregroundColor(isAvailable ? SP.Colors.textPrimary : SP.Colors.textTertiary)
                if isAvailable {
                    Text(String(localized: String.LocalizationValue(track.descriptionKey)))
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textTertiary)
                        .lineLimit(1)
                } else {
                    Text(String(localized: "soundscape.file_missing"))
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.warning)
                }
            }

            Spacer()

            // Preview button
            if isAvailable {
                Button {
                    SP.Haptic.light()
                    if isPreviewing {
                        ambient.stopPreview()
                    } else {
                        ambient.preview(track)
                    }
                } label: {
                    Image(systemName: isPreviewing ? "stop.circle.fill" : "play.circle")
                        .font(.system(size: 24))
                        .foregroundColor(trackColor(track))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
            }

            // Select indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(SP.Colors.heroGradient)
            } else if isAvailable {
                Circle()
                    .stroke(SP.Colors.textTertiary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: SP.Layout.cornerSmall, style: .continuous)
                .fill(isSelected ? trackColor(track).opacity(0.06) : Color.clear)
        )
        .onTapGesture {
            guard isAvailable else { return }
            SP.Haptic.selectionChanged()
            ambient.selectedTrack = track
        }
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

    private var scienceCard: some View {
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
        case .rainAmbient:  SP.Colors.calm
        case .forestCalm:   SP.Colors.success
        case .oceanWaves:   Color.teal
        case .softMelody:   SP.Colors.accent
        case .brownNoise:   SP.Colors.warmth
        }
    }
}
