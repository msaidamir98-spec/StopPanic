import SwiftUI

// MARK: - ProfileHubView

// Профиль + настройки + SOS контакты + экспорт.
// ✨ Glass cards, animated stats, premium treatment

struct ProfileHubView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(primaryColor: SP.Colors.accent, secondaryColor: SP.Colors.warmth)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader
                        statsOverview
                        sosContactsSection
                        settingsSection
                        aboutSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, SP.Layout.padding)
                    .padding(.top, 12)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddContact) {
                AddContactSheet()
                    .environment(coordinator)
            }
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                    appear = true
                    avatarScale = 1.0
                }
            }
        }
    }

    // MARK: Private

    @State
    private var showEditName = false
    @State
    private var editName = ""
    @State
    private var showAddContact = false
    @State
    private var appear = false
    @State
    private var avatarScale: CGFloat = 0.5

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var initials: String {
        let name = coordinator.userName
        if name.isEmpty { return "👤" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                // Glow rings
                ForEach(0 ..< 2, id: \.self) { i in
                    Circle()
                        .stroke(SP.Colors.accent.opacity(0.08 - Double(i) * 0.03), lineWidth: 1)
                        .frame(width: CGFloat(80 + i * 20), height: CGFloat(80 + i * 20))
                        .scaleEffect(appear ? 1 : 0.5)
                        .animation(SP.Anim.spring.delay(0.2 + Double(i) * 0.1), value: appear)
                }

                Circle()
                    .fill(SP.Colors.heroGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: SP.Colors.accent.opacity(0.3), radius: 12, y: 4)

                Text(initials)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(avatarScale)

            VStack(spacing: 4) {
                if coordinator.userName.isEmpty {
                    Button {
                        editName = coordinator.userName
                        showEditName = true
                    } label: {
                        Text("Укажи имя")
                            .font(SP.Typography.title2)
                            .foregroundColor(SP.Colors.accent)
                    }
                } else {
                    Text(coordinator.userName)
                        .font(SP.Typography.title1)
                        .foregroundColor(SP.Colors.textPrimary)
                        .onTapGesture {
                            editName = coordinator.userName
                            showEditName = true
                        }
                }

                Text("Участник Stillō")
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .opacity(appear ? 1 : 0)
        .alert("Имя", isPresented: $showEditName) {
            TextField("Введи имя", text: $editName)
            Button("Сохранить") {
                coordinator.userName = editName
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Stats

    private var statsOverview: some View {
        HStack(spacing: 12) {
            statTile("📝", coordinator.diaryService.diaryEpisodes.count, "Записей")
            statTile("🧘", coordinator.sessionsCompleted, "Сессий")
            statTile("🌬️", coordinator.totalBreathingMinutes, "мин")
            statTile(
                "🏆", coordinator.achievementService.achievements.filter(\.isUnlocked).count,
                "Наград"
            )
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.15), value: appear)
    }

    // MARK: - SOS Contacts

    private var sosContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(SP.Colors.danger)
                Text("SOS Контакты")
                    .font(SP.Typography.title3)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                Button {
                    showAddContact = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(SP.Colors.heroGradient)
                }
            }

            if coordinator.sosService.contacts.isEmpty {
                Text("Добавь людей, которым отправится SOS при панике")
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textTertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(coordinator.sosService.contacts.enumerated()), id: \.element.id) {
                    index, contact in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(SP.Colors.accent.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(contact.name.prefix(1)).uppercased())
                                    .font(SP.Typography.headline)
                                    .foregroundColor(SP.Colors.accent)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(contact.name)
                                .font(SP.Typography.headline)
                                .foregroundColor(SP.Colors.textPrimary)
                            Text(contact.phone)
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textTertiary)
                        }

                        Spacer()

                        if contact.notifyOnPanic {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 12))
                                .foregroundColor(SP.Colors.accent)
                        }

                        Button {
                            withAnimation(SP.Anim.springFast) {
                                coordinator.sosService.removeContact(at: index)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(SP.Colors.danger.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
                }
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.25), value: appear)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Настройки")
                .font(SP.Typography.title3)
                .foregroundColor(SP.Colors.textPrimary)

            settingsRow(icon: "bell.fill", title: "Уведомления", color: SP.Colors.accent) {
                coordinator.notificationService.requestAuthorization()
            }

            settingsRow(icon: "heart.fill", title: "Apple Health", color: SP.Colors.danger) {
                coordinator.healthManager.requestPermissions()
            }

            settingsRow(icon: "globe", title: "Телефон доверия", color: SP.Colors.success) {
                let line = SOSService.getCrisisLine()
                if let url = URL(string: "tel://\(line.replacingOccurrences(of: " ", with: ""))") {
                    UIApplication.shared.open(url)
                }
            }

            NavigationLink {
                ProfileView(service: coordinator.profileService)
            } label: {
                settingsRowLabel(
                    icon: "person.fill", title: "Подробный профиль", color: SP.Colors.warmth
                )
            }

            NavigationLink {
                MoodMapView(service: coordinator.moodMapService)
            } label: {
                settingsRowLabel(icon: "map.fill", title: "Карта настроений", color: SP.Colors.calm)
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 15)
        .animation(SP.Anim.spring.delay(0.35), value: appear)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: 8) {
            Text("Stillō")
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)
            Text("v\(appVersion) · Made with ❤️")
                .font(SP.Typography.caption)
                .foregroundColor(SP.Colors.textTertiary)
            Text(
                "⚠️ Это приложение НЕ заменяет профессиональную помощь.\nПри серьёзных проблемах обратитесь к врачу."
            )
            .font(SP.Typography.caption2)
            .foregroundColor(SP.Colors.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .opacity(appear ? 1 : 0)
        .animation(SP.Anim.spring.delay(0.45), value: appear)
    }

    private func statTile(_ emoji: String, _ value: Int, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text(emoji).font(.title3)
            AnimatedNumber(
                value: value,
                font: SP.Typography.headline,
                color: SP.Colors.textPrimary
            )
            Text(label)
                .font(SP.Typography.caption2)
                .foregroundColor(SP.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
    }

    private func settingsRow(
        icon: String, title: String, color: Color, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(SP.Colors.textTertiary)
            }
            .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
        }
        .buttonStyle(PremiumButtonStyle())
    }

    private func settingsRowLabel(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            Text(title)
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(SP.Colors.textTertiary)
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
    }
}

// MARK: - AddContactSheet

struct AddContactSheet: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        NavigationStack {
            ZStack {
                SP.Colors.bg.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Имя")
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.textTertiary)
                        TextField("Имя контакта", text: $name)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Телефон")
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.textTertiary)
                        TextField("+7...", text: $phone)
                            .textFieldStyle(.plain)
                            .keyboardType(.phonePad)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Кто это?")
                            .font(SP.Typography.caption)
                            .foregroundColor(SP.Colors.textTertiary)
                        TextField("Мама, друг, терапевт...", text: $relationship)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .foregroundColor(.white)
                    }

                    Toggle(isOn: $notifyOnPanic) {
                        Text("Уведомлять при SOS")
                            .font(SP.Typography.callout)
                            .foregroundColor(SP.Colors.textPrimary)
                    }
                    .tint(SP.Colors.accent)

                    Spacer()

                    Button {
                        let trimmedName = name.trimmingCharacters(in: .whitespaces)
                        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
                        guard !trimmedName.isEmpty, !trimmedPhone.isEmpty else { return }
                        let contact = SOSContact(
                            name: trimmedName, phone: trimmedPhone,
                            relationship: relationship.trimmingCharacters(in: .whitespaces),
                            notifyOnPanic: notifyOnPanic
                        )
                        coordinator.sosService.addContact(contact)
                        SP.Haptic.success()
                        dismiss()
                    } label: {
                        Text("Добавить контакт")
                            .spPrimaryButton()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || phone.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.top, 20)
            }
            .navigationTitle("Новый контакт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(SP.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var name = ""
    @State
    private var phone = ""
    @State
    private var relationship = ""
    @State
    private var notifyOnPanic = true
}
