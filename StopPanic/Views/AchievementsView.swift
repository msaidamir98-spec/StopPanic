import SwiftUI

/// Экран достижений
struct AchievementsView: View {
    // MARK: Internal

    @ObservedObject
    var service: AchievementService

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("🏆").font(.system(size: 50))
                        Text("\(service.totalPoints) очков")
                            .font(.title.bold()).foregroundColor(.white)
                        Text("\(service.achievements.filter(\.isUnlocked).count) / \(service.achievements.count)")
                            .font(.subheadline).foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 20)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(service.achievements) { a in
                            achievementCard(a)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationTitle("Достижения")
    }

    // MARK: Private

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    private func achievementCard(_ a: Achievement) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(a.isUnlocked ? AppTheme.primary.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 56, height: 56)
                Image(systemName: a.icon)
                    .font(.title3)
                    .foregroundColor(a.isUnlocked ? AppTheme.primary : .gray)
            }
            Text(a.title)
                .font(.subheadline.bold())
                .foregroundColor(a.isUnlocked ? .white : .gray)
                .multilineTextAlignment(.center)
            Text(a.description)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center).lineLimit(2)

            if !a.isUnlocked {
                ProgressView(value: a.progress).tint(AppTheme.primary)
                Text("\(a.currentProgress)/\(a.requirement)")
                    .font(.caption2).foregroundColor(.white.opacity(0.5))
            } else {
                Text("✅ Разблокировано")
                    .font(.caption2).foregroundColor(AppTheme.secondary)
            }
        }
        .padding(14)
        .background(Color.white.opacity(a.isUnlocked ? 0.08 : 0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(a.isUnlocked ? AppTheme.primary.opacity(0.3) : .clear, lineWidth: 1))
    }
}

#Preview { AchievementsView(service: AchievementService()) }
