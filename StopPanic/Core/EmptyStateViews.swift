import SwiftUI

// MARK: - EmptyStateView

// Красивые пустые состояния для всех экранов.
// Мотивирующий текст + мягкая анимация + CTA.

struct EmptyStateView: View {
    // MARK: Internal

    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                // Soft glow behind icon
                Circle()
                    .fill(SP.Colors.accent.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .scaleEffect(appear ? 1.1 : 0.8)
                    .animation(SP.Anim.float, value: appear)

                Circle()
                    .fill(SP.Colors.accent.opacity(0.04))
                    .frame(width: 160, height: 160)
                    .scaleEffect(appear ? 1.05 : 0.9)

                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SP.Colors.accent, SP.Colors.calm],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: floatOffset)
            }
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.6)

            VStack(spacing: 10) {
                Text(title)
                    .font(SP.Typography.title2)
                    .foregroundColor(SP.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 20)

            if let actionTitle, let action {
                Button(action: {
                    SP.Haptic.light()
                    action()
                }) {
                    Text(actionTitle)
                        .font(SP.Typography.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(SP.Colors.heroGradient)
                        .clipShape(Capsule())
                        .shadow(color: SP.Colors.accent.opacity(0.3), radius: 12, y: 6)
                }
                .buttonStyle(PremiumButtonStyle())
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 30)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { appear = true }
            withAnimation(
                .easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true)
            ) {
                floatOffset = -8
            }
        }
    }

    // MARK: Private

    @State
    private var appear = false
    @State
    private var floatOffset: CGFloat = 0
}

// MARK: - JournalEmptyState

struct JournalEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "book.closed.fill",
            title: String(localized: "empty.journal_title"),
            message: String(localized: "empty.journal_message"),
            actionTitle: String(localized: "empty.journal_action")
        )
    }
}

// MARK: - ToolsCompletedState

struct ToolsCompletedState: View {
    var body: some View {
        EmptyStateView(
            icon: "checkmark.seal.fill",
            title: String(localized: "empty.tools_done_title"),
            message: String(localized: "empty.tools_done_message")
        )
    }
}

// MARK: - HeartDataEmptyState

struct HeartDataEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "heart.text.square",
            title: String(localized: "empty.heart_title"),
            message: String(localized: "empty.heart_message"),
            actionTitle: String(localized: "empty.heart_action")
        )
    }
}

// MARK: - AchievementsEmptyState

struct AchievementsEmptyState: View {
    var body: some View {
        EmptyStateView(
            icon: "trophy.fill",
            title: String(localized: "empty.achievements_title"),
            message: String(localized: "empty.achievements_message"),
            actionTitle: String(localized: "empty.achievements_action")
        )
    }
}

// MARK: - SearchEmptyState

struct SearchEmptyState: View {
    let query: String

    var body: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: String(localized: "empty.search_title"),
            message: String(localized: "empty.search_message \(query)")
        )
    }
}
