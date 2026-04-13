import SwiftUI

// MARK: - ThemePickerView

/// Экран выбора темы — тёмная, светлая, авто.
struct ThemePickerView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.calm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    previewCard
                    themeSelectorCard
                    infoCard
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Оформление")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(SP.Anim.spring) { appear = true }
        }
    }

    // MARK: Private

    @State
    private var appear = false

    private var theme: ThemeManager {
        coordinator.themeManager
    }

    private var previewCard: some View {
        VStack(spacing: 16) {
            ZStack {
                // Preview card background
                RoundedRectangle(cornerRadius: SP.Layout.cornerMedium, style: .continuous)
                    .fill(theme.bgCard)
                    .frame(height: 180)
                    .shadow(color: theme.shadowSoft, radius: 16, y: 8)

                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(theme.heroGradient)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("S")
                                    .font(SP.Typography.headline)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.textPrimary.opacity(0.8))
                                .frame(width: 100, height: 12)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.textTertiary)
                                .frame(width: 70, height: 8)
                        }

                        Spacer()
                    }

                    HStack(spacing: 10) {
                        ForEach(["🧘", "🌬️", "📝"], id: \.self) { emoji in
                            VStack(spacing: 4) {
                                Text(emoji).font(.title3)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.textTertiary)
                                    .frame(width: 30, height: 6)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: SP.Layout.cornerSmall, style: .continuous)
                                    .fill(theme.isLight ? .thinMaterial : .ultraThinMaterial)
                            )
                        }
                    }

                    HStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(theme.heroGradient)
                            .frame(height: 36)
                            .overlay(
                                Text("SOS")
                                    .font(SP.Typography.caption)
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(16)
            }

            Text("Предпросмотр")
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
    }

    private var themeSelectorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Тема")
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            ForEach(AppTheme.allCases) { appTheme in
                Button {
                    withAnimation(SP.Anim.spring) {
                        theme.currentTheme = appTheme
                    }
                    SP.Haptic.selectionChanged()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(theme.currentTheme == appTheme
                                    ? SP.Colors.accent.opacity(0.15)
                                    : SP.Colors.textTertiary.opacity(0.08))
                                .frame(width: 40, height: 40)

                            Image(systemName: appTheme.icon)
                                .font(.system(size: 18))
                                .foregroundColor(theme.currentTheme == appTheme
                                    ? SP.Colors.accent
                                    : SP.Colors.textTertiary)
                        }

                        Text(appTheme.displayName)
                            .font(SP.Typography.callout)
                            .foregroundColor(SP.Colors.textPrimary)

                        Spacer()

                        if theme.currentTheme == appTheme {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(SP.Colors.heroGradient)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.1), value: appear)
    }

    private var infoCard: some View {
        VStack(spacing: 8) {
            Text("💡 Подсказка")
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)
            Text("Режим «Авто» подстраивается под настройки устройства. Тёмная тема лучше для вечера — она снижает нагрузку на глаза и помогает расслабиться.")
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .spGlassCard()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.2), value: appear)
    }
}
