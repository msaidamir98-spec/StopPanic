import SwiftUI

// MARK: - SoundscapeView

/// Экран атмосферных звуков: фоновая музыка + звуки природы.
/// Минималистичный UI, качественное микширование.

struct SoundscapeView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self) var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.calm, secondaryColor: SP.Colors.accent)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    masterSection
                    musicSection
                    natureSoundsSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.top, 12)
            }
            .background(ScrollBounceDisabler())
        }
        .navigationTitle(String(localized: "soundscape.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appear = true }
        }
    }

    // MARK: Private

    @State private var appear = false

    private var ambient: AmbientSoundService {
        coordinator.ambientSound
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(localized: "soundscape.title"))
                    .font(SP.Typography.title1)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                if ambient.isAnythingPlaying {
                    pulsingIndicator
                }
            }
            Text(String(localized: "soundscape.subtitle"))
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textSecondary)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : -10)
    }

    private var pulsingIndicator: some View {
        Circle()
            .fill(SP.Colors.success)
            .frame(width: 10, height: 10)
            .shadow(color: SP.Colors.success.opacity(0.5), radius: 4)
            .modifier(PulseModifier())
    }

    // MARK: - Master Volume

    private var masterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(SP.Colors.accent)
                Text(String(localized: "soundscape.master_volume"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                Text("\(Int(ambient.masterVolume * 100))%")
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textTertiary)
            }
            Slider(
                value: Binding<Double>(
                    get: { Double(ambient.masterVolume) },
                    set: { ambient.masterVolume = Float($0) }
                ),
                in: 0...1
            )
            .tint(SP.Colors.accent)
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.1), value: appear)
    }

    // MARK: - Music Section

    private var musicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(SP.Colors.warmth)
                Text(String(localized: "soundscape.music"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }

            // Music tracks
            ForEach(AmbientSoundService.MusicTrack.allCases) { track in
                musicTrackRow(track)
            }

            // Music volume
            if ambient.isMusicPlaying {
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .font(.caption)
                            .foregroundColor(SP.Colors.textTertiary)
                        Slider(
                            value: Binding<Double>(
                                get: { Double(ambient.musicVolume) },
                                set: { ambient.musicVolume = Float($0) }
                            ),
                            in: 0...1
                        )
                        .tint(SP.Colors.warmth)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.caption)
                            .foregroundColor(SP.Colors.textTertiary)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.2), value: appear)
    }

    private func musicTrackRow(_ track: AmbientSoundService.MusicTrack) -> some View {
        let isSelected = ambient.selectedMusic == track && ambient.isMusicPlaying

        return Button {
            SP.Haptic.selectionChanged()
            withAnimation(SP.Anim.springSnappy) {
                if isSelected {
                    ambient.stopMusic()
                } else {
                    ambient.selectedMusic = track
                    ambient.playMusic()
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text(track.emoji)
                    .font(.title3)
                Text(track.displayName)
                    .font(SP.Typography.subheadline)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                        .foregroundColor(SP.Colors.warmth)
                        .symbolEffect(.variableColor.iterative)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                isSelected
                    ? AnyShapeStyle(SP.Colors.warmth.opacity(0.12))
                    : AnyShapeStyle(Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nature Sounds Section

    private var natureSoundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(SP.Colors.success)
                Text(String(localized: "soundscape.nature"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }

            Text(String(localized: "soundscape.nature_hint"))
                .font(SP.Typography.caption2)
                .foregroundColor(SP.Colors.textTertiary)

            ForEach(AmbientSoundService.NatureSound.allCases) { sound in
                natureSoundRow(sound)
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.3), value: appear)
    }

    private func natureSoundRow(_ sound: AmbientSoundService.NatureSound) -> some View {
        let isActive = ambient.activeNatureSounds.contains(sound)

        return VStack(spacing: 6) {
            Button {
                SP.Haptic.selectionChanged()
                withAnimation(SP.Anim.springSnappy) {
                    ambient.toggleNatureSound(sound)
                }
            } label: {
                HStack(spacing: 12) {
                    Text(sound.emoji)
                        .font(.title3)
                    Text(sound.displayName)
                        .font(SP.Typography.subheadline)
                        .foregroundColor(SP.Colors.textPrimary)
                    Spacer()
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SP.Colors.heroGradient)
                    } else {
                        Circle()
                            .stroke(SP.Colors.textTertiary.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    isActive
                        ? AnyShapeStyle(SP.Colors.success.opacity(0.08))
                        : AnyShapeStyle(Color.clear)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            // Volume slider when active
            if isActive {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 10))
                        .foregroundColor(SP.Colors.textTertiary)
                    Slider(
                        value: Binding<Double>(
                            get: { Double(ambient.natureVolumes[sound] ?? 0.5) },
                            set: { ambient.setNatureVolume(sound, volume: Float($0)) }
                        ),
                        in: 0...1
                    )
                    .tint(SP.Colors.success)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 10))
                        .foregroundColor(SP.Colors.textTertiary)
                }
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - PulseModifier

private struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
