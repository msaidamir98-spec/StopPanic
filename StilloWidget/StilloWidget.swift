import SwiftUI
import WidgetKit

// MARK: - SOS Widget Entry

struct SOSWidgetEntry: TimelineEntry {
    let date: Date
}

// MARK: - SOS Widget Provider

struct SOSWidgetProvider: TimelineProvider {
    func placeholder(in _: Context) -> SOSWidgetEntry {
        SOSWidgetEntry(date: .now)
    }

    func getSnapshot(in _: Context, completion: @escaping (SOSWidgetEntry) -> Void) {
        completion(SOSWidgetEntry(date: .now))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<SOSWidgetEntry>) -> Void) {
        let entry = SOSWidgetEntry(date: .now)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - SOS Lock Screen Widget View

struct SOSWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: SOSWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryInline:
            inlineView
        case .accessoryRectangular:
            rectangularView
        default:
            circularView
        }
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("SOS")
                    .font(.system(size: 9, weight: .heavy))
            }
        }
        .widgetURL(URL(string: "stillo://sos"))
    }

    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "hand.raised.fill")
            Text("Stillō SOS")
        }
        .widgetURL(URL(string: "stillo://sos"))
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 24, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text("SOS")
                    .font(.system(size: 14, weight: .heavy))
                Text("Tap for help")
                    .font(.system(size: 10))
                    .opacity(0.7)
            }
        }
        .widgetURL(URL(string: "stillo://sos"))
    }
}

// MARK: - Breathing Lock Screen Widget

struct BreathWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: SOSWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Image(systemName: "wind")
                        .font(.system(size: 18, weight: .medium))
                    Text("4-7-8")
                        .font(.system(size: 9, weight: .bold))
                }
            }
            .widgetURL(URL(string: "stillo://breathe"))
        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "wind")
                Text("4-7-8 Breathing")
            }
            .widgetURL(URL(string: "stillo://breathe"))
        default:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "wind")
                    .font(.system(size: 20))
            }
            .widgetURL(URL(string: "stillo://breathe"))
        }
    }
}

// MARK: - SOS Widget Configuration

struct SOSWidget: Widget {
    let kind = "SOSWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SOSWidgetProvider()) { entry in
            SOSWidgetView(entry: entry)
        }
        .configurationDisplayName("SOS")
        .description("Quick access to emergency help")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

// MARK: - Breathing Widget Configuration

struct BreathWidget: Widget {
    let kind = "BreathWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SOSWidgetProvider()) { entry in
            BreathWidgetView(entry: entry)
        }
        .configurationDisplayName("4-7-8 Breathing")
        .description("Start breathing from Lock Screen")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

// MARK: - Widget Bundle

@main
struct StilloWidgetBundle: WidgetBundle {
    var body: some Widget {
        SOSWidget()
        BreathWidget()
    }
}
