import SwiftUI

// MARK: - JournalView

// Дневник панических атак + карта настроений + инсайты.
// ✨ Glass cards, staggered animations, animated numbers

struct JournalView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(primaryColor: SP.Colors.calm, secondaryColor: SP.Colors.accent)

                VStack(spacing: 0) {
                    header
                    segmentPicker

                    ScrollView(.vertical, showsIndicators: false) {
                        if selectedSegment == 0 {
                            diaryContent
                        } else if selectedSegment == 1 {
                            moodContent
                        } else {
                            insightsContent
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEpisodeSheet()
                    .environment(coordinator)
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    appear = true
                }
            }
        }
    }

    // MARK: Private

    @State
    private var showAddSheet = false
    @State
    private var selectedSegment = 0
    @State
    private var appear = false

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Дневник")
                    .font(SP.Typography.title1)
                    .foregroundColor(SP.Colors.textPrimary)
                Text("\(coordinator.diaryService.diaryEpisodes.count) записей")
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.textTertiary)
                    .contentTransition(.numericText())
            }

            Spacer()

            Button {
                SP.Haptic.light()
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(SP.Colors.heroGradient)
            }
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.top, 12)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : -15)
    }

    // MARK: - Segment

    private var segmentPicker: some View {
        HStack(spacing: 4) {
            segmentButton("Эпизоды", index: 0)
            segmentButton("Настроение", index: 1)
            segmentButton("Инсайты", index: 2)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.warmGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, SP.Layout.padding)
        .padding(.vertical, 12)
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Diary Content

    private var diaryContent: some View {
        VStack(spacing: 12) {
            if coordinator.diaryService.diaryEpisodes.isEmpty {
                emptyState(
                    icon: "book.closed.fill",
                    title: "Дневник пока пуст",
                    subtitle: "Записывай эпизоды, чтобы увидеть паттерны"
                )
            } else {
                weekSummaryCard

                ForEach(
                    Array(coordinator.diaryService.diaryEpisodes.sorted(by: { $0.date > $1.date }).enumerated()),
                    id: \.element.id
                ) { index, episode in
                    EpisodeCard(episode: episode)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 15)
                        .animation(SP.Anim.spring.delay(Double(index) * 0.04), value: appear)
                }
            }
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    private var weekSummaryCard: some View {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEp = coordinator.diaryService.diaryEpisodes.filter { $0.date >= weekAgo }
        let avgIntensity = weekEp.isEmpty ? 0 : weekEp.map(\.intensity).reduce(0, +) / weekEp.count

        return HStack(spacing: 16) {
            VStack(spacing: 4) {
                AnimatedNumber(
                    value: weekEp.count,
                    font: SP.Typography.bigNumber,
                    color: weekEp.count > 3 ? SP.Colors.danger : SP.Colors.accent
                )
                Text("за неделю")
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }

            Divider().frame(height: 40).overlay(Color.white.opacity(0.1))

            VStack(spacing: 4) {
                Text("\(avgIntensity)/10")
                    .font(SP.Typography.title2)
                    .foregroundColor(intensityColor(avgIntensity))
                Text("средняя сила")
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: weekEp.count <= 2 ? "arrow.down.right" : "arrow.up.right")
                    .font(.system(size: 20))
                    .foregroundColor(weekEp.count <= 2 ? SP.Colors.success : SP.Colors.warning)
                Text("тренд")
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    // MARK: - Mood Content

    private var moodContent: some View {
        VStack(spacing: 14) {
            if coordinator.moodMapService.points.isEmpty {
                emptyState(
                    icon: "map.fill",
                    title: "Карта настроений пуста",
                    subtitle: "Отмечай настроение в разных местах"
                )
            } else {
                ForEach(coordinator.moodMapService.points.sorted(by: { $0.date > $1.date })) { point in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(moodEmoji(point.mood))
                                    .font(.title2)
                                Text("\(point.mood)/10")
                                    .font(SP.Typography.headline)
                                    .foregroundColor(intensityColor(point.mood))
                            }
                            if !point.note.isEmpty {
                                Text(point.note)
                                    .font(SP.Typography.callout)
                                    .foregroundColor(SP.Colors.textSecondary)
                            }
                            Text(point.date.formatted(.dateTime.day().month().hour().minute()))
                                .font(SP.Typography.caption2)
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                        Spacer()
                    }
                    .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
                }
            }
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Insights Content

    private var insightsContent: some View {
        VStack(spacing: 14) {
            NavigationLink {
                PanicRadarView(predictionService: coordinator.predictionService)
            } label: {
                ToolCardLabel(
                    icon: "dot.radiowaves.left.and.right",
                    title: "Радар паники",
                    subtitle: "Предсказание на основе данных",
                    color: SP.Colors.accent
                )
            }

            NavigationLink {
                AchievementsView(service: coordinator.achievementService)
            } label: {
                ToolCardLabel(
                    icon: "trophy.fill",
                    title: "Достижения",
                    subtitle: "\(coordinator.achievementService.achievements.filter(\.isUnlocked).count)/\(coordinator.achievementService.achievements.count) разблокировано",
                    color: SP.Colors.warning
                )
            }

            if !coordinator.diaryService.diaryEpisodes.isEmpty {
                triggersCard
            }
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    private var triggersCard: some View {
        let allNotes = coordinator.diaryService.diaryEpisodes.suffix(30)
            .map(\.notes).joined(separator: " ").lowercased()
        let triggerMap = [
            "работа": ("💼", "Работа"), "сон": ("😴", "Недосып"),
            "кофе": ("☕", "Кофеин"), "метро": ("🚇", "Транспорт"),
            "толпа": ("👥", "Толпа"), "ночь": ("🌙", "Ночь"),
            "еда": ("🍔", "Еда"), "спорт": ("🏃", "Спорт"),
        ]
        let found = triggerMap.compactMap { allNotes.contains($0.key) ? $0.value : nil }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(SP.Colors.warning)
                Text("Частые триггеры")
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }

            if found.isEmpty {
                Text("Записывайте больше эпизодов, чтобы обнаружить паттерны")
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textTertiary)
            } else {
                HStack(spacing: 10) {
                    ForEach(found, id: \.1) { emoji, name in
                        VStack(spacing: 4) {
                            Text(emoji).font(.title2)
                            Text(name)
                                .font(SP.Typography.caption2)
                                .foregroundColor(SP.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    private func segmentButton(_ title: String, index: Int) -> some View {
        Button {
            SP.Haptic.selectionChanged()
            withAnimation(SP.Anim.springSnappy) {
                selectedSegment = index
            }
        } label: {
            Text(title)
                .font(SP.Typography.subheadline)
                .foregroundColor(selectedSegment == index ? .white : SP.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    selectedSegment == index
                        ? AnyShapeStyle(SP.Colors.heroGradient)
                        : AnyShapeStyle(Color.clear)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Helpers

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(SP.Colors.textTertiary)
            Text(title)
                .font(SP.Typography.title3)
                .foregroundColor(SP.Colors.textSecondary)
            Text(subtitle)
                .font(SP.Typography.callout)
                .foregroundColor(SP.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func intensityColor(_ value: Int) -> Color {
        switch value {
        case 1 ... 3: SP.Colors.success
        case 4 ... 6: SP.Colors.warning
        case 7 ... 8: .orange
        default: SP.Colors.danger
        }
    }

    private func moodEmoji(_ mood: Int) -> String {
        switch mood {
        case 1 ... 2: "😰"
        case 3 ... 4: "😟"
        case 5 ... 6: "😐"
        case 7 ... 8: "🙂"
        default: "😊"
        }
    }
}

// MARK: - EpisodeCard

struct EpisodeCard: View {
    // MARK: Internal

    let episode: DiaryEpisode

    var body: some View {
        HStack(spacing: 14) {
            // Intensity indicator with glow
            ZStack {
                Circle()
                    .fill(intensityColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .shadow(color: intensityColor.opacity(0.2), radius: 6)
                Text("\(episode.intensity)")
                    .font(SP.Typography.headline)
                    .foregroundColor(intensityColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.notes.isEmpty ? "Без заметок" : episode.notes)
                    .font(SP.Typography.callout)
                    .foregroundColor(SP.Colors.textPrimary)
                    .lineLimit(2)

                Text(episode.date.formatted(.dateTime.day().month().hour().minute()))
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }

            Spacer()
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
    }

    // MARK: Private

    private var intensityColor: Color {
        switch episode.intensity {
        case 1 ... 3: SP.Colors.success
        case 4 ... 6: SP.Colors.warning
        case 7 ... 8: .orange
        default: SP.Colors.danger
        }
    }
}

// MARK: - AddEpisodeSheet

struct AddEpisodeSheet: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        NavigationStack {
            ZStack {
                coordinator.themeManager.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Intensity
                        VStack(spacing: 12) {
                            HStack {
                                Text("Сила эпизода")
                                    .font(SP.Typography.headline)
                                    .foregroundColor(SP.Colors.textPrimary)
                                Spacer()
                                Text("\(Int(intensity))/10")
                                    .font(SP.Typography.title2)
                                    .foregroundColor(sliderColor)
                                    .contentTransition(.numericText())
                            }

                            Slider(value: $intensity, in: 1 ... 10, step: 1)
                                .tint(sliderColor)

                            Text(intensityLabel)
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)

                        // Triggers
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Что могло вызвать?")
                                .font(SP.Typography.headline)
                                .foregroundColor(SP.Colors.textPrimary)

                            FlowLayoutView(items: triggerOptions) { trigger in
                                Button {
                                    SP.Haptic.selectionChanged()
                                    withAnimation(SP.Anim.springSnappy) {
                                        if selectedTriggers.contains(trigger) {
                                            selectedTriggers.remove(trigger)
                                        } else {
                                            selectedTriggers.insert(trigger)
                                        }
                                    }
                                } label: {
                                    Text(trigger)
                                        .font(SP.Typography.subheadline)
                                        .foregroundColor(
                                            selectedTriggers.contains(trigger)
                                                ? .white : SP.Colors.textSecondary
                                        )
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedTriggers.contains(trigger)
                                                ? AnyShapeStyle(SP.Colors.heroGradient)
                                                : AnyShapeStyle(.warmGlass)
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    selectedTriggers.contains(trigger)
                                                        ? SP.Colors.accent.opacity(0.4)
                                                        : Color.white.opacity(0.08),
                                                    lineWidth: 0.5
                                                )
                                        )
                                }
                            }
                        }
                        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)

                        // Notes
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Заметки")
                                .font(SP.Typography.headline)
                                .foregroundColor(SP.Colors.textPrimary)

                            TextField("Что произошло? Как себя чувствуешь?", text: $notes, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.warmGlass)
                                )
                                .foregroundColor(SP.Colors.textPrimary)
                                .frame(minHeight: 80)
                        }

                        // Save
                        Button {
                            let triggerText = selectedTriggers.joined(separator: ", ")
                            let fullNotes = [notes, triggerText].filter { !$0.isEmpty }.joined(separator: " | Триггеры: ")
                            coordinator.diaryService.addDiaryEpisode(
                                intensity: Int(intensity),
                                notes: fullNotes
                            )
                            coordinator.achievementService.updateProgress(id: "diary_master")
                            coordinator.refreshPredictions()
                            SP.Haptic.success()
                            dismiss()
                        } label: {
                            Text("Сохранить запись")
                                .spPrimaryButton()
                        }
                    }
                    .padding(.horizontal, SP.Layout.padding)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Новая запись")
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
    private var intensity: Double = 5
    @State
    private var notes = ""
    @State
    private var selectedTriggers: Set<String> = []

    private let triggerOptions = [
        "💼 Работа", "🚇 Транспорт", "👥 Толпа", "🌙 Ночь",
        "☕ Кофеин", "😴 Недосып", "💊 Лекарства", "🏥 Здоровье",
        "💰 Деньги", "👨‍👩‍👧 Семья", "📱 Соцсети", "❓ Без причины",
    ]

    private var sliderColor: Color {
        switch Int(intensity) {
        case 1 ... 3: SP.Colors.success
        case 4 ... 6: SP.Colors.warning
        case 7 ... 8: .orange
        default: SP.Colors.danger
        }
    }

    private var intensityLabel: String {
        switch Int(intensity) {
        case 1 ... 2: "Лёгкая тревога"
        case 3 ... 4: "Умеренная тревога"
        case 5 ... 6: "Сильная тревога"
        case 7 ... 8: "Паническая атака"
        default: "Сильная паника"
        }
    }
}

// MARK: - FlowLayoutView

struct FlowLayoutView<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder
    let content: (Item) -> Content

    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .padding(.trailing, 6)
                        .padding(.bottom, 6)
                        .alignmentGuide(.leading) { d in
                            if abs(width - d.width) > geo.size.width {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item == items.last {
                                width = 0
                            } else {
                                width -= d.width
                            }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item == items.last {
                                height = 0
                            }
                            return result
                        }
                }
            }
        }
        .frame(height: 120) // approximate
    }
}
