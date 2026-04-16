import SwiftUI

// MARK: - SoundscapeView

/// Премиальный экран выбора звука (уровень Calm/Headspace).
/// Звуки разбиты по категориям: Nature / Melody.
/// Превью 5 сек, выбор → автозапуск при SOS и медитации.

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
                    headerSection(ambient)
                    sosHintCard
                    categoryTabs(ambient)
                    playButton(ambient)
                    volumeControl(ambient)
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
    @State private var selectedCategory: AmbientSoundService.SoundCategory = .nature

    // MARK: - Header (Now Playing)

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

    // MARK: - Category Tabs + Track List

    private func categoryTabs(_ ambient: AmbientSoundService) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Segment control
            HStack(spacing: 0) {
                ForEach(AmbientSoundService.SoundCategory.allCases) { cat in
                    Button {
                        withAnimation(SP.Anim.springSnappy) { selectedCategory = cat }
                        SP.Haptic.light()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 14))
                            Text(String(localized: String.LocalizationValue(cat.nameKey)))
                                .font(SP.Typography.subheadline)
                        }
                        .foregroundColor(selectedCategory == cat ? .white : SP.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(selectedCategory == cat ? AnyShapeStyle(SP.Colors.heroGradient) : AnyShapeStyle(Color.clear))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Capsule().fill(.warmGlass))

            // Track list for selected category
            ForEach(AmbientSoundService.SoundTrack.tracks(for: selectedCategory)) { track in
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
            ZStack {
                Circle()
                    .fill(trackColor(track).opacity(isSelected ? 0.2 : 0.08))
                    .frame(width: 48, height: 48)
                Image(systemName: track.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isAvailable ? trackColor(track) : SP.Colors.textTertiary)
            }

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
                    isPreviewing ? ambient.stopPreview() : ambient.preview(track)
                } label: {
                    Image(systemName: isPreviewing ? "stop.circle.fill" : "play.circle")
                        .font(.system(size: 26))
                        .foregroundColor(trackColor(track))
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
            }

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(SP.Colors.heroGradient)
            } else if isAvailable {
                Circle()
                    .stroke(SP.Colors.textTertiary.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: SP.Layout.cornerSmall, style: .continuous)
                .fill(isSelected ? trackColor(track).opacity(0.06) : Color.clear)
        )
        .onTapGesture {
            guard isAvailable else { return }
            SP.Haptic.selectionChanged()
            ambient.selectedTrack = track
            // Switch to the category of the selected track
            withAnimation(SP.Anim.springSnappy) {
                selectedCategory = track.category
            }
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
        case .rainAmbient:      SP.Colors.calm
        case .forestCalm:       SP.Colors.success
        case .oceanWaves:       Color.teal
        case .pianoMeditation:  SP.Colors.accent
        case .fluteMeditation:  Color.indigo
        case .underwaterAmbience: Color.cyan
        }
    }
}

// MARK: - Inline Sound Picker (for BreathingSessionView / CalmSessionView)

/// Компактный пикер звука — встраивается прямо в экран медитации/дыхания.
/// Показывает текущий трек, кнопку play/stop, ползунок громкости.
struct InlineSoundPicker: View {
    let ambient: AmbientSoundService
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed: current track + play/stop
            Button {
                withAnimation(SP.Anim.springSnappy) { expanded.toggle() }
                SP.Haptic.light()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: ambient.selectedTrack.icon)
                        .font(.system(size: 16))
                        .foregroundColor(trackColor)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(trackColor.opacity(0.12)))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(String(localized: String.LocalizationValue(ambient.selectedTrack.nameKey)))
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.textPrimary)
                        Text(String(localized: "soundscape.background_sound"))
                            .font(.system(size: 10))
                            .foregroundColor(SP.Colors.textTertiary)
                    }

                    Spacer()

                    // Play/Stop
                    Button {
                        SP.Haptic.selectionChanged()
                        ambient.toggle()
                    } label: {
                        Image(systemName: ambient.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(trackColor)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SP.Colors.textTertiary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            // Expanded: track list + volume
            if expanded {
                VStack(spacing: 10) {
                    Divider().overlay(Color.white.opacity(0.06))

                    // Quick track selector (horizontal scroll)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ambient.availableTracks) { track in
                                trackChip(track)
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    // Volume slider
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 10))
                            .foregroundColor(SP.Colors.textTertiary)
                        Slider(value: Binding(
                            get: { ambient.volume },
                            set: { ambient.volume = $0 }
                        ), in: 0...1)
                        .tint(trackColor)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 10))
                            .foregroundColor(SP.Colors.textTertiary)
                        Text("\(Int(ambient.volume * 100))%")
                            .font(.system(size: 10))
                            .monospacedDigit()
                            .foregroundColor(SP.Colors.textTertiary)
                            .frame(width: 30)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: SP.Layout.cornerSmall, style: .continuous)
                .fill(.warmGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: SP.Layout.cornerSmall, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    private func trackChip(_ track: AmbientSoundService.SoundTrack) -> some View {
        let isSelected = ambient.selectedTrack == track
        let color = chipColor(track)

        return Button {
            SP.Haptic.selectionChanged()
            ambient.selectedTrack = track
        } label: {
            HStack(spacing: 5) {
                Image(systemName: track.icon)
                    .font(.system(size: 12))
                Text(String(localized: String.LocalizationValue(track.nameKey)))
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : SP.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(color) : AnyShapeStyle(color.opacity(0.1)))
            )
        }
        .buttonStyle(.plain)
    }

    private var trackColor: Color { chipColor(ambient.selectedTrack) }

    private func chipColor(_ track: AmbientSoundService.SoundTrack) -> Color {
        switch track {
        case .rainAmbient:      SP.Colors.calm
        case .forestCalm:       SP.Colors.success
        case .oceanWaves:       Color.teal
        case .pianoMeditation:  SP.Colors.accent
        case .fluteMeditation:  Color.indigo
        case .underwaterAmbience: Color.cyan
        }
    }
}
