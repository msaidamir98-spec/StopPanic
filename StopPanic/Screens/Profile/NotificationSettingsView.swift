import SwiftUI

// MARK: - NotificationSettingsView

/// Экран настройки уведомлений — включение, время напоминания о дыхании.
struct NotificationSettingsView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.calm)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Authorization Status

                    statusCard

                    // MARK: - Breathing Reminder

                    breathingReminderCard

                    // MARK: - Info

                    infoCard
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Уведомления")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkStatus()
            withAnimation(SP.Anim.spring) { appear = true }
        }
    }

    // MARK: Private

    @State
    private var isAuthorized = false
    @State
    private var breathingReminder = true
    @State
    private var reminderHour = 10
    @State
    private var reminderMinute = 0
    @State
    private var appear = false
    @State
    private var showTimePicker = false

    private var statusCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isAuthorized ? SP.Colors.success.opacity(0.15) : SP.Colors.danger.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isAuthorized ? SP.Colors.success : SP.Colors.danger)
            }

            Text(isAuthorized ? "Уведомления включены" : "Уведомления выключены")
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            Text(isAuthorized
                ? "Stillō может напоминать о дыхательных практиках"
                : "Разреши уведомления, чтобы не забывать о практиках")
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
                .multilineTextAlignment(.center)

            if !isAuthorized {
                Button {
                    requestPermission()
                } label: {
                    Text("Разрешить уведомления")
                        .spPrimaryButton()
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .spGlassCard()
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
    }

    private var breathingReminderCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "lungs.fill")
                    .foregroundColor(SP.Colors.calm)
                Text("Напоминание о дыхании")
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                Toggle("", isOn: $breathingReminder)
                    .tint(SP.Colors.accent)
                    .labelsHidden()
            }

            if breathingReminder {
                Divider().background(SP.Colors.textTertiary.opacity(0.3))

                Button {
                    showTimePicker.toggle()
                } label: {
                    HStack {
                        Text("Время")
                            .font(SP.Typography.callout)
                            .foregroundColor(SP.Colors.textSecondary)
                        Spacer()
                        Text(String(format: "%02d:%02d", reminderHour, reminderMinute))
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.accent)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(SP.Colors.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                if showTimePicker {
                    HStack(spacing: 0) {
                        Picker("Час", selection: $reminderHour) {
                            ForEach(0 ..< 24, id: \.self) { h in
                                Text(String(format: "%02d", h))
                                    .tag(h)
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()

                        Text(":")
                            .font(SP.Typography.title1)
                            .foregroundColor(SP.Colors.textPrimary)

                        Picker("Минута", selection: $reminderMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Text(String(format: "%02d", m))
                                    .tag(m)
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()
                    }
                    .frame(height: 120)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Button {
                    saveReminder()
                } label: {
                    Text("Сохранить напоминание")
                        .font(SP.Typography.callout)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: SP.Layout.cornerSmall, style: .continuous)
                                .fill(SP.Colors.heroGradient)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .spGlassCard()
        .animation(SP.Anim.spring, value: breathingReminder)
        .animation(SP.Anim.spring, value: showTimePicker)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.1), value: appear)
    }

    private var infoCard: some View {
        VStack(spacing: 8) {
            Text("💡 Как это работает")
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)
            Text("Stillō отправит мягкое напоминание в выбранное время. Дыхательная практика занимает всего 2 минуты и доказанно снижает уровень кортизола.")
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

    private func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    private func requestPermission() {
        coordinator.notificationService.requestPermissions()
        // Re-check after a short delay (system dialog takes time)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            checkStatus()
        }
    }

    private func saveReminder() {
        if breathingReminder {
            coordinator.notificationService.scheduleBreathingReminder(
                hour: reminderHour, minute: reminderMinute
            )
            SP.Haptic.success()
        } else {
            coordinator.notificationService.cancelAll()
            SP.Haptic.light()
        }
    }
}

import UserNotifications
