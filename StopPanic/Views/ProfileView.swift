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
                            TextField("Имя", text: $editingName)
                                .textFieldStyle(.plain)
                                .font(SP.Typography.title2)
                                .multilineTextAlignment(.center)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                                .foregroundColor(.white)
                                .padding(.horizontal, 60)
                                .onSubmit { saveName() }
                        } else {
                            Text(service.displayName.isEmpty ? "Укажи имя" : service.displayName)
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
                            Text(isEditing ? "Сохранить" : "Редактировать")
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
        .navigationTitle("Профиль")
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
                title: "Записей",
                value: "\(coordinator.diaryService.diaryEpisodes.count)",
                color: SP.Colors.accent
            )
            statCard(
                title: "Сессий",
                value: "\(coordinator.sessionsCompleted)",
                color: SP.Colors.warmth
            )
            statCard(
                title: "Мин дыхания",
                value: "\(coordinator.totalBreathingMinutes)",
                color: SP.Colors.calm
            )
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("О приложении")
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            Text("StopPanic — твой помощник в борьбе с паническими атаками. 100% бесплатно, без рекламы, без подписок.")
                .font(SP.Typography.body)
                .foregroundColor(SP.Colors.textSecondary)
                .lineSpacing(4)

            Text("Версия 1.0.0")
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
