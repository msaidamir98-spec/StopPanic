import Combine
import SwiftUI

// MARK: - Profile View

struct ProfileView: View {
    // MARK: Internal

    @ObservedObject
    var service: UserProfileService
    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.calm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(SP.Colors.accent.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Text(avatarEmoji)
                            .font(.system(size: 44))
                    }
                    .opacity(appear ? 1 : 0)
                    .scaleEffect(appear ? 1 : 0.7)

                    // Name
                    VStack(spacing: 6) {
                        if isEditing {
                            TextField(String(localized: "profile.name"), text: $editingName)
                                .textFieldStyle(.plain)
                                .font(SP.Typography.title2)
                                .multilineTextAlignment(.center)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.warmGlass)
                                )
                                .foregroundColor(.white)
                                .padding(.horizontal, 60)
                                .onSubmit { saveName() }
                        } else {
                            Text(service.displayName.isEmpty ? String(localized: "profile.set_name") : service.displayName)
                                .font(SP.Typography.title1)
                                .foregroundColor(SP.Colors.textPrimary)
                        }

                        Button {
                            SP.Haptic.light()
                            if isEditing {
                                saveName()
                            } else {
                                editingName = service.displayName
                                isEditing = true
                            }
                        } label: {
                            Text(isEditing ? String(localized: "general.save") : String(localized: "profile.edit"))
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.accent)
                        }
                    }
                    .opacity(appear ? 1 : 0)

                    // Stats
                    statsSection
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                    // Info
                    infoSection
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 30)
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle(String(localized: "profile.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
    }

    // MARK: Private

    @State
    private var editingName = ""
    @State
    private var isEditing = false
    @State
    private var appear = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    // MARK: - Helpers

    private var avatarEmoji: String {
        let name = service.displayName.lowercased()
        if name.isEmpty { return "🧘" }
        let emojis = ["😊", "💪", "🌟", "🧠", "❤️", "🦋", "🌈", "🎯"]
        let index = abs(name.hashValue) % emojis.count
        return emojis[index]
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(
                title: String(localized: "profile.entries"),
                value: "\(coordinator.diaryService.diaryEpisodes.count)",
                color: SP.Colors.accent
            )
            statCard(
                title: String(localized: "profile.sessions"),
                value: "\(coordinator.sessionsCompleted)",
                color: SP.Colors.warmth
            )
            statCard(
                title: String(localized: "profile.breath_min"),
                value: "\(coordinator.totalBreathingMinutes)",
                color: SP.Colors.calm
            )
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "profile.about"))
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            Text(String(localized: "profile.about_body"))
                .font(SP.Typography.body)
                .foregroundColor(SP.Colors.textSecondary)
                .lineSpacing(4)

            Text(String(localized: "profile.version \(appVersion)"))
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
        }
        .spGlassCard()
    }

    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SP.Typography.title2)
                .foregroundColor(color)
                .contentTransition(.numericText())
            Text(title)
                .font(SP.Typography.caption2)
                .foregroundColor(SP.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
    }

    private func saveName() {
        service.displayName = editingName
        isEditing = false
        SP.Haptic.success()
    }
}
