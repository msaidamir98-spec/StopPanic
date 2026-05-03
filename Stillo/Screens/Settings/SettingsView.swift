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
                    soundscapeSection
                    appearanceSection
                    notificationsSection
                    healthSection
                    crisisSection
                    PrivacySettingsView()
                    #if DEBUG
                    debugSection
                    #endif
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

    // MARK: - Voice Guide Section

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "speaker.wave.2.fill", title: String(localized: "settings.voice_guide"), color: SP.Colors.calm)

            Toggle(String(localized: "settings.voice_enabled"), isOn: Binding(
                get: { coordinator.audioGuide.isVoiceEnabled },
                set: {
                    SP.Haptic.selectionChanged()
                    coordinator.audioGuide.isVoiceEnabled = $0
                }
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

                }

                // Show current active source
                let source = coordinator.audioGuide.activeSource
                HStack(spacing: 8) {
                    Circle()
                        .fill(source == .voiceBank ? SP.Colors.success : SP.Colors.calm)
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
                            .font(.system(.footnote))
                        Text(String(localized: "settings.voice_bank_ready"))
                            .font(SP.Typography.caption2)
                            .foregroundColor(SP.Colors.success)
                        Spacer()
                    }
                }

                // Volume slider
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "settings.voice_volume"))
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textTertiary)
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.fill")
                            .font(.system(.caption2))
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
                            .font(.system(.caption2))
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

                // Premium voice tip
                premiumVoiceTip
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.05), value: appear)
    }

    private var premiumVoiceTip: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(.footnote))
                    .foregroundColor(SP.Colors.accent)
                Text(String(localized: "settings.voice_premium_tip_title"))
                    .font(SP.Typography.subheadline)
                    .foregroundColor(SP.Colors.textPrimary)
            }
            Text(String(localized: "settings.voice_premium_tip_body"))
                .font(SP.Typography.caption2)
                .foregroundColor(SP.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SP.Layout.cornerSmall)
                .fill(SP.Colors.accent.opacity(0.08))
        )
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
                    .font(.system(.callout))
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
                    .font(.system(.caption))
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
                    .font(.system(.caption))
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
                    .font(.system(.caption))
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
                    .font(.system(.caption))
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
        }
        .buttonStyle(.plain)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.3), value: appear)
    }

    // MARK: - Crisis Lines

    private var crisisSection: some View {
        NavigationLink {
            CrisisLineView()
        } label: {
            HStack(spacing: 12) {
                sectionIcon(icon: "phone.fill", color: SP.Colors.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "settings.crisis_lines"))
                        .font(SP.Typography.callout)
                        .foregroundColor(SP.Colors.textPrimary)
                    Text(String(localized: "settings.crisis_lines_sub"))
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(.caption))
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
        }
        .buttonStyle(.plain)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.4), value: appear)
    }

    // MARK: - Debug (DEBUG-only, никогда не попадает в Release)

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "hammer.fill", title: "Developer", color: SP.Colors.warning)

            Toggle(isOn: Binding(
                get: { coordinator.premiumManager.isGodModeEnabled },
                set: {
                    SP.Haptic.selectionChanged()
                    coordinator.premiumManager.isGodModeEnabled = $0
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🛠 God Mode")
                        .font(SP.Typography.callout)
                        .foregroundColor(SP.Colors.textPrimary)
                    Text("Unlock all premium content (DEBUG only)")
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textTertiary)
                }
            }
            .tint(SP.Colors.warning)

            if coordinator.premiumManager.isGodModeEnabled {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(SP.Colors.warning)
                        .font(.system(.footnote))
                    Text("All paywalls bypassed")
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.warning)
                    Spacer()
                }
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.45), value: appear)
    }
    #endif

    // MARK: - Helpers

    private func voiceSourceLabel(_ source: AudioGuideService.VoiceSource) -> String {
        switch source {
        case .voiceBank: String(localized: "settings.voice_source_bank")
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
                .font(.system(.footnote))
                .foregroundColor(color)
        }
    }
}
