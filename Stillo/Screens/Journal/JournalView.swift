import SwiftUI

// MARK: - JournalView

// Дневник тревожных эпизодов + карта настроений + инсайты.
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

                    if selectedSegment == 0 {
                        diaryListContent
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            if selectedSegment == 1 {
                                moodContent
                            } else {
                                insightsContent
                            }
                        }
                        .background(ScrollBounceDisabler())
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEpisodeSheet()
                    .environment(coordinator)
            }
            .sheet(item: $editingEpisode) { episode in
                EditEpisodeSheet(episode: episode)
                    .environment(coordinator)
            }
            .sheet(item: $editingMoodPoint) { point in
                EditMoodSheet(point: point)
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
    @State
    private var editingEpisode: DiaryEpisode?
    @State
    private var editingMoodPoint: MoodPoint?

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "journal.title"))
                    .font(SP.Typography.title1)
                    .foregroundColor(SP.Colors.textPrimary)
                Text("\(coordinator.diaryService.diaryEpisodes.count) \(String(localized: "journal.entries"))")
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
            segmentButton(String(localized: "journal.episodes"), index: 0)
            segmentButton(String(localized: "journal.mood"), index: 1)
            segmentButton(String(localized: "journal.insights"), index: 2)
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

    // MARK: - Diary Content (List-based for native swipe-to-delete)

    private var sortedEpisodes: [DiaryEpisode] {
        coordinator.diaryService.diaryEpisodes.sorted(by: { $0.date > $1.date })
    }

    private var diaryListContent: some View {
        Group {
            if coordinator.diaryService.diaryEpisodes.isEmpty {
                ScrollView {
                    emptyState(
                        icon: "book.closed.fill",
                        title: String(localized: "journal.empty.title"),
                        subtitle: String(localized: "journal.empty.subtitle")
                    )
                    .padding(.horizontal, SP.Layout.padding)
                }
            } else {
                List {
                    Section {
                        weekSummaryCard
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: SP.Layout.padding, bottom: 4, trailing: SP.Layout.padding))
                    }

                    Section {
                        ForEach(sortedEpisodes) { episode in
                            EpisodeCard(episode: episode)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: SP.Layout.padding, bottom: 4, trailing: SP.Layout.padding))
                                .onTapGesture {
                                    SP.Haptic.light()
                                    editingEpisode = episode
                                }
                                .contextMenu {
                                    Button {
                                        editingEpisode = episode
                                    } label: {
                                        Label(String(localized: "journal.edit"), systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        coordinator.diaryService.removeEpisodeById(episode.id)
                                    } label: {
                                        Label(String(localized: "journal.delete"), systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        coordinator.diaryService.removeEpisodeById(episode.id)
                                    } label: {
                                        Label(String(localized: "journal.delete"), systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        editingEpisode = episode
                                    } label: {
                                        Label(String(localized: "journal.edit"), systemImage: "pencil")
                                    }
                                    .tint(SP.Colors.accent)
                                }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
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
                Text(String(localized: "journal.perWeek"))
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }

            Divider().frame(height: 40).overlay(Color.white.opacity(0.1))

            VStack(spacing: 4) {
                Text("\(avgIntensity)/10")
                    .font(SP.Typography.title2)
                    .foregroundColor(intensityColor(avgIntensity))
                Text(String(localized: "journal.avgIntensity"))
                    .font(SP.Typography.caption2)
                    .foregroundColor(SP.Colors.textTertiary)
            }

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: weekEp.count <= 2 ? "arrow.down.right" : "arrow.up.right")
                    .font(.system(size: 20))
                    .foregroundColor(weekEp.count <= 2 ? SP.Colors.success : SP.Colors.warning)
                Text(String(localized: "journal.trend"))
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
                    title: String(localized: "journal.mood_empty_title"),
                    subtitle: String(localized: "journal.mood_empty_subtitle")
                )
            } else {
                // Mini chart
                moodMiniChart

                // Mood entries list with swipe actions
                ForEach(coordinator.moodMapService.points.sorted(by: { $0.date > $1.date })) { point in
                    MoodPointCard(point: point)
                        .onTapGesture {
                            SP.Haptic.light()
                            editingMoodPoint = point
                        }
                        .contextMenu {
                            Button {
                                editingMoodPoint = point
                            } label: {
                                Label(String(localized: "journal.edit"), systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                withAnimation {
                                    coordinator.moodMapService.removePointById(point.id)
                                }
                            } label: {
                                Label(String(localized: "journal.delete"), systemImage: "trash")
                            }
                        }
                }
            }
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    private var moodMiniChart: some View {
        let recent = Array(coordinator.moodMapService.points.suffix(14))
        let avg = recent.isEmpty ? 0.0 : Double(recent.map(\.mood).reduce(0, +)) / Double(recent.count)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "journal.mood_trend"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
                Spacer()
                Text(String(format: "Ø %.1f", avg))
                    .font(SP.Typography.caption)
                    .foregroundColor(SP.Colors.accent)
            }

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(recent) { point in
                    VStack(spacing: 2) {
                        Text(moodEmoji(point.mood))
                            .font(.system(size: 10))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(moodBarColor(point.mood))
                            .frame(width: 16, height: CGFloat(point.mood) * 6 + 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    private func moodBarColor(_ mood: Int) -> Color {
        switch mood {
        case 1...3: SP.Colors.calm
        case 4...6: SP.Colors.accent
        case 7...8: SP.Colors.success
        default: SP.Colors.success
        }
    }

    // MARK: - Insights Content

    private var insightsContent: some View {
        VStack(spacing: 14) {
            NavigationLink {
                PanicRadarView(predictionService: coordinator.predictionService)
            } label: {
                ToolCardLabel(
                    icon: "dot.radiowaves.left.and.right",
                    title: String(localized: "tools_patterns_title"),
                    subtitle: String(localized: "tools_patterns_sub"),
                    color: SP.Colors.accent
                )
            }

            NavigationLink {
                AchievementsView(service: coordinator.achievementService)
            } label: {
                ToolCardLabel(
                    icon: "trophy.fill",
                    title: String(localized: "journal.achievements"),
                    subtitle: "\(coordinator.achievementService.achievements.filter(\.isUnlocked).count)/\(coordinator.achievementService.achievements.count) \(String(localized: "journal.unlocked"))",
                    color: SP.Colors.warning
                )
            }

            // Time-of-day analysis
            if !coordinator.diaryService.diaryEpisodes.isEmpty {
                timeOfDayCard
                weeklyProgressCard
                triggersCard
            }
        }
        .padding(.horizontal, SP.Layout.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Time of Day Analysis

    private var timeOfDayCard: some View {
        let episodes = coordinator.diaryService.diaryEpisodes
        let cal = Calendar.current

        let morning = episodes.filter { (5..<12).contains(cal.component(.hour, from: $0.date)) }
        let afternoon = episodes.filter { (12..<17).contains(cal.component(.hour, from: $0.date)) }
        let evening = episodes.filter { (17..<22).contains(cal.component(.hour, from: $0.date)) }
        let night = episodes.filter {
            let h = cal.component(.hour, from: $0.date)
            return h >= 22 || h < 5
        }

        let data: [(String, String, Int, Color)] = [
            ("🌅", String(localized: "insight.morning"), morning.count, SP.Colors.warmth),
            ("☀️", String(localized: "insight.afternoon"), afternoon.count, SP.Colors.warning),
            ("🌆", String(localized: "insight.evening"), evening.count, SP.Colors.accent),
            ("🌙", String(localized: "insight.night"), night.count, SP.Colors.calm),
        ]
        let maxCount = max(1, data.map(\.2).max() ?? 1)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(SP.Colors.accent)
                Text(String(localized: "insight.time_of_day"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }

            Text(String(localized: "insight.time_description"))
                .font(SP.Typography.caption2)
                .foregroundColor(SP.Colors.textTertiary)

            ForEach(data, id: \.1) { emoji, label, count, color in
                HStack(spacing: 10) {
                    Text(emoji)
                    Text(label)
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.7))
                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
                    }
                    .frame(height: 16)
                    Text("\(count)")
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    // MARK: - Weekly Progress Card

    private var weeklyProgressCard: some View {
        let cal = Calendar.current
        let episodes = coordinator.diaryService.diaryEpisodes

        // Last 4 weeks comparison
        var weeks: [(String, Int, Int)] = [] // label, count, avgIntensity
        for w in 0..<4 {
            let end = cal.date(byAdding: .day, value: -(w * 7), to: Date())!
            let start = cal.date(byAdding: .day, value: -7, to: end)!
            let weekEps = episodes.filter { $0.date >= start && $0.date < end }
            let avg = weekEps.isEmpty ? 0 : weekEps.map(\.intensity).reduce(0, +) / weekEps.count
            let label = w == 0 ? String(localized: "insight.this_week")
                      : w == 1 ? String(localized: "insight.last_week")
                      : "\(w) " + String(localized: "insight.weeks_ago")
            weeks.append((label, weekEps.count, avg))
        }
        weeks.reverse()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(SP.Colors.success)
                Text(String(localized: "insight.weekly_progress"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack {
                    Text(week.0)
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textSecondary)
                        .frame(width: 80, alignment: .leading)
                    HStack(spacing: 4) {
                        ForEach(0..<max(1, week.1), id: \.self) { _ in
                            Circle()
                                .fill(intensityColor(week.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                    Spacer()
                    Text("\(week.1)")
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                }
            }

            // Trend message
            let current = weeks.last?.1 ?? 0
            let previous = weeks.dropLast().last?.1 ?? 0
            if current < previous {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.right")
                        .foregroundColor(SP.Colors.success)
                    Text(String(localized: "insight.trend_improving"))
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.success)
                }
                .padding(.top, 4)
            } else if current > previous {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(SP.Colors.warning)
                    Text(String(localized: "insight.trend_attention"))
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.warning)
                }
                .padding(.top, 4)
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)
    }

    private var triggersCard: some View {
        let allNotes = coordinator.diaryService.diaryEpisodes.suffix(30)
            .map(\.notes).joined(separator: " ").lowercased()
        // Multi-language trigger keywords — search in user's diary notes
        let triggerMap: [Set<String>: (String, String)] = [
            ["работа", "work", "arbeit", "trabajo", "travail", "仕事", "工作", "trabalho"]: ("💼", String(localized: "trigger_stress")),
            ["сон", "sleep", "schlaf", "sueño", "sommeil", "睡眠", "sono"]: ("😴", String(localized: "trigger_sleep")),
            ["кофе", "coffee", "kaffee", "café", "コーヒー", "咖啡"]: ("☕", String(localized: "trigger_caffeine")),
            ["метро", "metro", "subway", "u-bahn", "地下鉄", "地铁", "metrô"]: ("🚇", String(localized: "trigger_transport")),
            ["толпа", "crowd", "menge", "multitud", "foule", "群衆", "人群", "multidão"]: ("👥", String(localized: "trigger_crowds")),
            ["ночь", "night", "nacht", "noche", "nuit", "夜", "noite"]: ("🌙", String(localized: "trigger_night")),
            ["еда", "food", "essen", "comida", "nourriture", "食事", "食物"]: ("🍔", String(localized: "journal.trigger_food")),
            ["спорт", "sport", "exercise", "deporte", "exercice", "運動", "运动", "esporte"]: ("🏃", String(localized: "journal.trigger_sport")),
        ]
        let found = triggerMap.compactMap { keys, value in
            keys.contains(where: { allNotes.contains($0) }) ? value : nil
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(SP.Colors.warning)
                Text(String(localized: "journal.common_triggers"))
                    .font(SP.Typography.headline)
                    .foregroundColor(SP.Colors.textPrimary)
            }

            if found.isEmpty {
                Text(String(localized: "journal.triggers_empty"))
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
                Text(episode.notes.isEmpty ? String(localized: "journal.no_notes") : episode.notes)
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
                                Text(String(localized: "journal.add_intensity"))
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
                            Text(String(localized: "journal.add_triggers"))
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
                            Text(String(localized: "journal.add_notes"))
                                .font(SP.Typography.headline)
                                .foregroundColor(SP.Colors.textPrimary)

                            TextField(String(localized: "journal.add_notes_placeholder"), text: $notes, axis: .vertical)
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
                            let fullNotes = [notes, triggerText].filter { !$0.isEmpty }
                                .joined(separator: " | \(String(localized: "journal.add_triggers_prefix"))")
                            coordinator.diaryService.addDiaryEpisode(
                                intensity: Int(intensity),
                                notes: fullNotes
                            )
                            // Auto-sync mood map: inverse intensity → mood (10 = great, 1 = awful)
                            let moodValue = max(1, 11 - Int(intensity))
                            coordinator.moodMapService.addPoint(mood: moodValue, note: fullNotes)
                            coordinator.achievementService.updateProgress(id: "diary_master")
                            coordinator.refreshPredictions()
                            SP.Haptic.success()
                            dismiss()
                        } label: {
                            Text(String(localized: "journal.add_save"))
                                .spPrimaryButton()
                        }
                    }
                    .padding(.horizontal, SP.Layout.padding)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(String(localized: "journal.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) { dismiss() }
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
        "💼 \(String(localized: "trigger_opt_work"))", "🚇 \(String(localized: "trigger_opt_transport"))",
        "👥 \(String(localized: "trigger_opt_crowds"))",
        "🌙 \(String(localized: "trigger_opt_night"))",
        "☕ \(String(localized: "trigger_opt_caffeine"))", "😴 \(String(localized: "trigger_opt_sleep"))", "💊 \(String(localized: "trigger_opt_meds"))",
        "🏥 \(String(localized: "trigger_opt_health"))",
        "💰 \(String(localized: "trigger_opt_money"))", "👨‍👩‍👧 \(String(localized: "trigger_opt_family"))", "📱 \(String(localized: "trigger_opt_social"))",
        "❓ \(String(localized: "trigger_opt_none"))",
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
        case 1 ... 2: String(localized: "journal.intensity_1")
        case 3 ... 4: String(localized: "journal.intensity_2")
        case 5 ... 6: String(localized: "journal.intensity_3")
        case 7 ... 8: String(localized: "journal.intensity_4")
        default: String(localized: "journal.intensity_5")
        }
    }
}

// MARK: - EditEpisodeSheet

struct EditEpisodeSheet: View {
    // MARK: Internal

    let episode: DiaryEpisode

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
                                Text(String(localized: "journal.add_intensity"))
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
                        }
                        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)

                        // Notes
                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(localized: "journal.add_notes"))
                                .font(SP.Typography.headline)
                                .foregroundColor(SP.Colors.textPrimary)

                            TextField(String(localized: "journal.add_notes_placeholder"), text: $notes, axis: .vertical)
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
                            coordinator.diaryService.updateEpisode(
                                id: episode.id,
                                intensity: Int(intensity),
                                notes: notes
                            )
                            coordinator.refreshPredictions()
                            SP.Haptic.success()
                            dismiss()
                        } label: {
                            Text(String(localized: "journal.add_save"))
                                .spPrimaryButton()
                        }

                        // Delete
                        Button(role: .destructive) {
                            coordinator.diaryService.removeEpisodeById(episode.id)
                            coordinator.refreshPredictions()
                            SP.Haptic.warning()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text(String(localized: "journal.delete"))
                            }
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(SP.Colors.danger.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: SP.Layout.cornerSmall))
                        }
                    }
                    .padding(.horizontal, SP.Layout.padding)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(String(localized: "journal.edit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) { dismiss() }
                        .foregroundColor(SP.Colors.textSecondary)
                }
            }
        }
        .onAppear {
            intensity = Double(episode.intensity)
            notes = episode.notes
        }
    }

    // MARK: Private

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var intensity: Double = 5
    @State
    private var notes = ""

    private var sliderColor: Color {
        switch Int(intensity) {
        case 1 ... 3: SP.Colors.success
        case 4 ... 6: SP.Colors.warning
        case 7 ... 8: .orange
        default: SP.Colors.danger
        }
    }
}

// MARK: - MoodPointCard

struct MoodPointCard: View {
    let point: MoodPoint

    var body: some View {
        HStack(spacing: 12) {
            Text(moodEmoji(point.mood))
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(point.mood)/10")
                        .font(SP.Typography.headline)
                        .foregroundColor(moodColor)
                    Spacer()
                    Text(point.date.formatted(.dateTime.day().month().hour().minute()))
                        .font(SP.Typography.caption2)
                        .foregroundColor(SP.Colors.textTertiary)
                }
                if !point.note.isEmpty {
                    Text(point.note)
                        .font(SP.Typography.callout)
                        .foregroundColor(SP.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .spGlassCard(cornerRadius: SP.Layout.cornerSmall)
    }

    private func moodEmoji(_ mood: Int) -> String {
        switch mood {
        case 1...2: "😰"
        case 3...4: "😟"
        case 5...6: "😐"
        case 7...8: "🙂"
        default: "😊"
        }
    }

    private var moodColor: Color {
        switch point.mood {
        case 1...3: SP.Colors.calm
        case 4...6: SP.Colors.accent
        case 7...8: SP.Colors.success
        default: SP.Colors.success
        }
    }
}

// MARK: - EditMoodSheet

struct EditMoodSheet: View {
    let point: MoodPoint

    @Environment(AppCoordinator.self) var coordinator
    @Environment(\.dismiss) private var dismiss

    @State private var mood: Double = 5
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                coordinator.themeManager.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Mood emoji
                        Text(moodEmoji(Int(mood)))
                            .font(.system(size: 64))
                            .contentTransition(.symbolEffect(.replace))

                        // Mood slider
                        VStack(spacing: 12) {
                            HStack {
                                Text(String(localized: "mood.how_feel"))
                                    .font(SP.Typography.headline)
                                    .foregroundColor(SP.Colors.textPrimary)
                                Spacer()
                                Text("\(Int(mood))/10")
                                    .font(SP.Typography.title2)
                                    .foregroundColor(sliderColor)
                                    .contentTransition(.numericText())
                            }

                            Slider(value: $mood, in: 1...10, step: 1)
                                .tint(sliderColor)
                        }
                        .spGlassCard(cornerRadius: SP.Layout.cornerMedium)

                        // Note
                        VStack(alignment: .leading, spacing: 10) {
                            Text(String(localized: "journal.add_notes"))
                                .font(SP.Typography.headline)
                                .foregroundColor(SP.Colors.textPrimary)

                            TextField(String(localized: "mood.note_optional"), text: $note, axis: .vertical)
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
                            coordinator.moodMapService.updatePoint(id: point.id, mood: Int(mood), note: note)
                            SP.Haptic.success()
                            dismiss()
                        } label: {
                            Text(String(localized: "journal.add_save"))
                                .spPrimaryButton()
                        }

                        // Delete
                        Button(role: .destructive) {
                            coordinator.moodMapService.removePointById(point.id)
                            SP.Haptic.warning()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text(String(localized: "journal.delete"))
                            }
                            .font(SP.Typography.headline)
                            .foregroundColor(SP.Colors.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(SP.Colors.danger.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: SP.Layout.cornerSmall))
                        }
                    }
                    .padding(.horizontal, SP.Layout.padding)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(String(localized: "journal.edit_mood_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "general.cancel")) { dismiss() }
                        .foregroundColor(SP.Colors.textSecondary)
                }
            }
        }
        .onAppear {
            mood = Double(point.mood)
            note = point.note
        }
    }

    private func moodEmoji(_ mood: Int) -> String {
        switch mood {
        case 1...2: "😰"
        case 3...4: "😟"
        case 5...6: "😐"
        case 7...8: "🙂"
        default: "😊"
        }
    }

    private var sliderColor: Color {
        switch Int(mood) {
        case 1...3: SP.Colors.calm
        case 4...6: SP.Colors.accent
        case 7...8: SP.Colors.success
        default: SP.Colors.success
        }
    }
}

// MARK: - FlowLayoutView

struct FlowLayoutView<Item: Hashable, Content: View>: View {
    // MARK: Internal

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
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: FlowHeightPreferenceKey.self, value: geo.size.height)
                }
            )
        }
        .onPreferenceChange(FlowHeightPreferenceKey.self) { totalHeight = $0 }
        .frame(height: totalHeight)
    }

    // MARK: Private

    @State
    private var totalHeight: CGFloat = 10
}

// MARK: - FlowHeightPreferenceKey

private struct FlowHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 10

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
