import SwiftUI

// MARK: - Mood Map View

struct MoodMapView: View {
    // MARK: Internal

    var service: MoodMapService

    var body: some View {
        ZStack {
            AmbientBackground(primaryColor: SP.Colors.calm, secondaryColor: SP.Colors.accent)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "mood.title"))
                            .font(SP.Typography.title1)
                            .foregroundColor(SP.Colors.textPrimary)
                        Text(String(localized: "mood.subtitle"))
                            .font(SP.Typography.callout)
                            .foregroundColor(SP.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(appear ? 1 : 0)

                    // Chart
                    if !service.points.isEmpty {
                        moodChart
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 20)
                    }

                    // Add button
                    Button {
                        SP.Haptic.light()
                        showAddSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(String(localized: "mood.add_mood"))
                        }
                        .spPrimaryButton()
                    }
                    .opacity(appear ? 1 : 0)

                    // History
                    if service.points.isEmpty {
                        VStack(spacing: 12) {
                            Text("📊")
                                .font(.system(size: 48))
                            Text(String(localized: "mood.empty_title"))
                                .font(SP.Typography.headline)
                                .foregroundColor(SP.Colors.textPrimary)
                            Text(String(localized: "mood.empty_body"))
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                        .spGlassCard()
                    } else {
                        historyList
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 30)
                    }
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle(String(localized: "mood.nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
        }
        .sheet(isPresented: $showAddSheet) {
            addMoodSheet
        }
    }

    // MARK: Private

    @State
    private var newMood: Double = 5
    @State
    private var newNote = ""
    @State
    private var showAddSheet = false
    @State
    private var appear = false

    private var averageMood: Double? {
        guard !service.points.isEmpty else { return nil }
        let sum = service.points.reduce(0) { $0 + $1.mood }
        return Double(sum) / Double(service.points.count)
    }

    // MARK: - Chart

    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "mood.last_7_days"))
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            let recent = Array(service.points.suffix(14))
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(recent) { point in
                    VStack(spacing: 4) {
                        Text(moodEmoji(point.mood))
                            .font(.caption)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(moodColor(point.mood))
                            .frame(width: 20, height: CGFloat(point.mood) * 8 + 8)
                        Text("\(point.mood)")
                            .font(SP.Typography.caption2)
                            .foregroundColor(SP.Colors.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            if let avg = averageMood {
                HStack {
                    Text(String(localized: "mood.average"))
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                    Text(String(format: "%.1f", avg))
                        .font(SP.Typography.headline)
                        .foregroundColor(moodColor(Int(avg.rounded())))
                    Text("/10")
                        .font(SP.Typography.caption)
                        .foregroundColor(SP.Colors.textTertiary)
                }
            }
        }
        .spGlassCard()
    }

    // MARK: - History

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "mood.history"))
                .font(SP.Typography.headline)
                .foregroundColor(SP.Colors.textPrimary)

            ForEach(service.points.reversed().prefix(20)) { point in
                HStack(spacing: 12) {
                    Text(moodEmoji(point.mood))
                        .font(.title2)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("\(point.mood)/10")
                                .font(SP.Typography.headline)
                                .foregroundColor(moodColor(point.mood))
                            Spacer()
                            Text(point.date.formatted(.dateTime.day().month().hour().minute()))
                                .font(SP.Typography.caption2)
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                        if !point.note.isEmpty {
                            Text(point.note)
                                .font(SP.Typography.caption)
                                .foregroundColor(SP.Colors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .spGlassCard()
    }

    // MARK: - Add Sheet

    private var addMoodSheet: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(primaryColor: SP.Colors.calm, secondaryColor: SP.Colors.accent)

                VStack(spacing: 28) {
                    Spacer()

                    Text(moodEmoji(Int(newMood)))
                        .font(.system(size: 64))

                    Text(String(localized: "mood.how_feel"))
                        .font(SP.Typography.title2)
                        .foregroundColor(SP.Colors.textPrimary)

                    VStack(spacing: 8) {
                        Slider(value: $newMood, in: 1 ... 10, step: 1)
                            .tint(moodColor(Int(newMood)))
                        HStack {
                            Text(String(localized: "mood.awful"))
                                .font(SP.Typography.caption2)
                                .foregroundColor(SP.Colors.textTertiary)
                            Spacer()
                            Text("\(Int(newMood))/10")
                                .font(SP.Typography.title3)
                                .foregroundColor(moodColor(Int(newMood)))
                            Spacer()
                            Text(String(localized: "mood.great"))
                                .font(SP.Typography.caption2)
                                .foregroundColor(SP.Colors.textTertiary)
                        }
                    }
                    .padding(.horizontal, 16)

                    TextField(String(localized: "mood.note_optional"), text: $newNote)
                        .textFieldStyle(.plain)
                        .font(SP.Typography.body)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SP.Colors.bgCard.opacity(0.8))
                        )
                        .foregroundColor(SP.Colors.textPrimary)

                    Spacer()

                    Button {
                        SP.Haptic.success()
                        service.addPoint(mood: Int(newMood), note: newNote)
                        newMood = 5
                        newNote = ""
                        showAddSheet = false
                    } label: {
                        Text(String(localized: "general.save"))
                            .spPrimaryButton()
                    }
                }
                .padding(.horizontal, SP.Layout.padding)
                .padding(.bottom, 40)
            }
            .navigationTitle(String(localized: "mood.mood"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "general.cancel")) { showAddSheet = false }
                        .foregroundColor(SP.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func moodEmoji(_ mood: Int) -> String {
        switch mood {
        case 1 ... 2: "☁️"
        case 3 ... 4: "🌤️"
        case 5 ... 6: "☀️"
        case 7 ... 8: "😊"
        case 9 ... 10: "🌟"
        default: "☀️"
        }
    }

    private func moodColor(_ mood: Int) -> Color {
        switch mood {
        case 1 ... 3: SP.Colors.calm
        case 4 ... 5: SP.Colors.accent
        case 6 ... 7: SP.Colors.accent
        case 8 ... 10: SP.Colors.success
        default: SP.Colors.accent
        }
    }
}
