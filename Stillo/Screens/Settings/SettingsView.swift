import AVFoundation
import SwiftUI

// MARK: - SettingsView

/// Полноценный экран настроек приложения.
/// Собирает все опции: голос, звуки, тема, уведомления, здоровье, экспорт.

struct SettingsView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self) var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.bgSoft, secondaryColor: SP.Colors.accent)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    voiceSection
                    openAISection
                    soundscapeSection
                    appearanceSection
                    notificationsSection
                    healthSection
                    dataSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.top, 12)
            }
            .background(ScrollBounceDisabler())
        }
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appear = true }
        }
    }

    // MARK: Private

    @State private var appear = false
    @State private var showAPIKeyField = false

    // MARK: - Voice Guide Section

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "speaker.wave.2.fill", title: String(localized: "settings.voice_guide"), color: SP.Colors.calm)

            Toggle(String(localized: "settings.voice_enabled"), isOn: Binding(
                get: { coordinator.audioGuide.isVoiceEnabled },
                set: { coordinator.audioGuide.isVoiceEnabled = $0 }
            ))
            .font(SP.Typography.callout)
            .foregroundColor(SP.Colors.textPrimary)
            .tint(SP.Colors.accent)

            if coordinator.audioGuide.isVoiceEnabled {
                // Voice source picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "settings.voice_source"))
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)

                    // Pre-recorded
                    voiceSourceRow(
                        source: .voiceBank,
                        icon: "waveform.badge.magnifyingglass",
                        title: String(localized: "settings.voice_source_bank"),
                        subtitle: coordinator.voiceBank.availablePhraseCount > 0
                            ? "\(coordinator.voiceBank.availablePhraseCount) " + String(localized: "settings.voice_phrases")
                            : String(localized: "settings.voice_no_phrases")
                    )

                    // System voice (AVSpeech)
                    voiceSourceRow(
                        source: .system,
                        icon: "person.wave.2.fill",
                        title: String(localized: "settings.voice_source_system"),
                        subtitle: String(localized: "settings.voice_system_hint")
                    )

                    // OpenAI TTS
                    voiceSourceRow(
                        source: .openAI,
                        icon: "waveform.circle.fill",
                        title: String(localized: "settings.voice_source_openai"),
                        subtitle: coordinator.ttsService.isReady
                            ? String(localized: "settings.voice_openai_ready")
                            : String(localized: "settings.voice_openai_need_key")
                    )
                }

                // Show current active source
                let source = coordinator.audioGuide.activeSource
                HStack(spacing: 8) {
                    Circle()
                        .fill(source == .voiceBank ? SP.Colors.success : source == .openAI ? SP.Colors.accent : SP.Colors.calm)
                        .frame(width: 8, height: 8)
                    Text(voiceSourceLabel(source))
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textSecondary)
                    Spacer()
                }

                // Voice bank info
                if coordinator.voiceBank.availablePhraseCount > 0 && coordinator.audioGuide.preferredSource == .voiceBank {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(SP.Colors.success)
                            .font(.system(size: 14))
                        Text(String(localized: "settings.voice_bank_ready"))
                            .font(SP.Typography.caption2)
                            .foregroundColor(SP.Colors.success)
                        Spacer()
                    }
                }

                // System voice picker (only when system source is selected)
                if coordinator.audioGuide.preferredSource == .system {
                    systemVoicePicker
                }

                // Volume slider
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "settings.voice_volume"))
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textTertiary)
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 10))
                            .foregroundColor(SP.Colors.textTertiary)
                        Slider(
                            value: Binding(
                                get: { Double(coordinator.voiceBank.volume) },
                                set: { coordinator.voiceBank.volume = Float($0) }
                            ),
                            in: 0.1...1.0
                        )
                        .tint(SP.Colors.accent)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 10))
                            .foregroundColor(SP.Colors.textTertiary)
                    }
                }

                // Test button
                Button {
                    SP.Haptic.light()
                    coordinator.audioGuide.speakSafe()
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text(String(localized: "settings.test_voice"))
                    }
                    .font(SP.Typography.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(SP.Colors.heroGradient)
                    .clipShape(RoundedRectangle(cornerRadius: SP.Layout.cornerSmall))
                }
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.05), value: appear)
    }

    private func voiceSourceRow(source: AudioGuideService.VoiceSource, icon: String, title: String, subtitle: String) -> some View {
        Button {
            SP.Haptic.selectionChanged()
            withAnimation(SP.Anim.springSnappy) {
                coordinator.audioGuide.preferredSource = source
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(coordinator.audioGuide.preferredSource == source ? SP.Colors.accent : SP.Colors.textTertiary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SP.Typography.subheadline)
                        .foregroundColor(SP.Colors.textPrimary)
                    Text(subtitle)
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textTertiary)
                }
                Spacer()
                if coordinator.audioGuide.preferredSource == source {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SP.Colors.heroGradient)
                } else {
                    Circle()
                        .stroke(SP.Colors.textTertiary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var systemVoicePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "voice.select_voice"))
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)

            let voices = coordinator.audioGuide.availableVoices
            let selectedId = Binding<String>(
                get: { coordinator.audioGuide.selectedVoiceId ?? "__auto__" },
                set: { newValue in
                    if newValue == "__auto__" {
                        coordinator.audioGuide.selectedVoiceId = nil
                    } else {
                        coordinator.audioGuide.selectedVoiceId = newValue
                    }
                    SP.Haptic.selectionChanged()
                }
            )

            Picker(String(localized: "voice.select_voice"), selection: selectedId) {
                Text(String(localized: "voice.auto_best"))
                    .tag("__auto__")

                ForEach(voices, id: \.identifier) { voice in
                    HStack {
                        Text(voice.name)
                        if voice.quality == .premium {
                            Text("★")
                        } else if voice.quality == .enhanced {
                            Text("✦")
                        }
                    }
                    .tag(voice.identifier)
                }
            }
            .pickerStyle(.inline)
            .frame(maxHeight: 200)
            .tint(SP.Colors.accent)
        }
    }

    // MARK: - OpenAI TTS (Optional Premium)

    private var openAISection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "waveform.circle.fill", title: "OpenAI TTS", color: SP.Colors.accent)

            Text(String(localized: "settings.openai_description"))
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textSecondary)

            Toggle(String(localized: "settings.openai_enabled"), isOn: Binding(
                get: { coordinator.ttsService.isEnabled },
                set: { coordinator.ttsService.isEnabled = $0 }
            ))
            .font(SP.Typography.callout)
            .foregroundColor(SP.Colors.textPrimary)
            .tint(SP.Colors.accent)

            if coordinator.ttsService.isEnabled {
                // API Key
                VStack(alignment: .leading, spacing: 6) {
                    Text("API Key")
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)

                    HStack {
                        if showAPIKeyField {
                            TextField("sk-...", text: Binding(
                                get: { coordinator.ttsService.apiKey },
                                set: { coordinator.ttsService.apiKey = $0 }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(SP.Colors.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        } else {
                            Text(coordinator.ttsService.apiKey.isEmpty
                                ? String(localized: "settings.openai_no_key")
                                : "sk-••••••••\(coordinator.ttsService.apiKey.suffix(4))")
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textSecondary)
                        }
                        Spacer()
                        Button {
                            withAnimation { showAPIKeyField.toggle() }
                        } label: {
                            Image(systemName: showAPIKeyField ? "checkmark.circle" : "pencil.circle")
                                .foregroundColor(SP.Colors.accent)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.warmGlass)
                    )
                }

                // Voice selection
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "settings.openai_voice"))
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)

                    ForEach(OpenAITTSService.TTSVoice.allCases) { voice in
                        Button {
                            SP.Haptic.selectionChanged()
                            coordinator.ttsService.selectedVoice = voice
                        } label: {
                            HStack(spacing: 10) {
                                Text(voice.emoji)
                                Text(voice.displayName)
                                    .font(SP.Typography.subheadline)
                                    .foregroundColor(SP.Colors.textPrimary)
                                Spacer()
                                if coordinator.ttsService.selectedVoice == voice {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SP.Colors.heroGradient)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Test button
                Button {
                    SP.Haptic.light()
                    coordinator.ttsService.speak(String(localized: "voice.you_are_safe"))
                } label: {
                    HStack {
                        if coordinator.ttsService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.circle.fill")
                        }
                        Text(String(localized: "settings.openai_test"))
                    }
                    .font(SP.Typography.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(SP.Colors.heroGradient)
                    .clipShape(RoundedRectangle(cornerRadius: SP.Layout.cornerSmall))
                }
                .disabled(coordinator.ttsService.apiKey.isEmpty)
                .opacity(coordinator.ttsService.apiKey.isEmpty ? 0.5 : 1)

                // Model picker
                Picker(String(localized: "settings.openai_model"), selection: Binding(
                    get: { coordinator.ttsService.selectedModel },
                    set: { coordinator.ttsService.selectedModel = $0 }
                )) {
                    ForEach(OpenAITTSService.TTSModel.allCases, id: \.rawValue) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.1), value: appear)
    }

    // MARK: - Soundscape

    private var soundscapeSection: some View {
        NavigationLink {
            SoundscapeView()
                .environment(coordinator)
        } label: {
            HStack(spacing: 12) {
                sectionIcon(icon: "music.note.list", color: SP.Colors.warmth)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "settings.soundscape"))
                        .font(SP.Typography.callout)
                        .foregroundColor(SP.Colors.textPrimary)
                    Text(String(localized: "settings.soundscape_sub"))
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textTertiary)
                }
                Spacer()
                if coordinator.ambientSound.isAnythingPlaying {
                    Circle()
                        .fill(SP.Colors.success)
                        .frame(width: 8, height: 8)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
        }
        .buttonStyle(.plain)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.15), value: appear)
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        NavigationLink {
            ThemePickerView()
                .environment(coordinator)
        } label: {
            HStack(spacing: 12) {
                sectionIcon(icon: "paintbrush.fill", color: SP.Colors.accentSoft)
                Text(String(localized: "settings.appearance"))
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
        }
        .buttonStyle(.plain)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.2), value: appear)
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        NavigationLink {
            NotificationSettingsView()
        } label: {
            HStack(spacing: 12) {
                sectionIcon(icon: "bell.fill", color: SP.Colors.accent)
                Text(String(localized: "settings.notifications"))
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
        }
        .buttonStyle(.plain)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.25), value: appear)
    }

    // MARK: - Health

    private var healthSection: some View {
        NavigationLink {
            HealthKitSettingsView()
        } label: {
            HStack(spacing: 12) {
                sectionIcon(icon: "heart.fill", color: SP.Colors.danger)
                Text("Apple Health")
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
        }
        .buttonStyle(.plain)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.3), value: appear)
    }

    // MARK: - Data

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "externaldrive.fill", title: String(localized: "settings.data"), color: SP.Colors.textSecondary)

            Button {
                coordinator.ttsService.clearCache()
                SP.Haptic.success()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash.circle")
                        .foregroundColor(SP.Colors.warning)
                    Text(String(localized: "settings.clear_tts_cache"))
                        .font(SP.Typography.subheadline)
                        .foregroundColor(SP.Colors.textPrimary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            NavigationLink {
                CrisisLineView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(SP.Colors.success)
                    Text(String(localized: "settings.crisis_lines"))
                        .font(SP.Typography.subheadline)
                        .foregroundColor(SP.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(SP.Colors.textTertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.35), value: appear)
    }

    // MARK: - Helpers

    private func voiceSourceLabel(_ source: AudioGuideService.VoiceSource) -> String {
        switch source {
        case .voiceBank: String(localized: "settings.voice_source_bank")
        case .openAI: String(localized: "settings.voice_source_openai")
        case .system: String(localized: "settings.voice_source_system")
        }
    }

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            sectionIcon(icon: icon, color: color)
            Text(title)
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)
        }
    }

    private func sectionIcon(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
        }
    }
}
