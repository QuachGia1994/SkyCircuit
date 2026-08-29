import ActivityKit
import SwiftUI
import WidgetKit

@main
struct SkyCircuitWidgets: WidgetBundle {
    var body: some Widget {
        DailyRunWidget()
        DailyRunLiveActivity()
    }
}

struct DailyRunWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SkyCircuitDailyRun", provider: DailyRunProvider()) { entry in
            HStack {
                VStack(alignment: .leading) {
                    Text("Daily Run")
                        .font(.caption.bold())
                    Text("🔥 \(entry.streak) day streak")
                        .font(.headline)
                    Text("Mini rank #\(entry.rank)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("🚀")
                    .font(.largeTitle)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Run")
        .description("Daily streak and mini leaderboard rank.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailyRunEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let rank: Int
}

struct DailyRunProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyRunEntry {
        DailyRunEntry(date: .now, streak: 7, rank: 42)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyRunEntry) -> Void) {
        completion(DailyRunEntry(date: .now, streak: 7, rank: 42))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyRunEntry>) -> Void) {
        let entry = DailyRunEntry(date: .now, streak: 7, rank: 42)
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 30))))
    }
}

struct DailyRunLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DailyRunAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily Run")
                        .font(.headline)
                    Spacer()
                    Text("#\(context.state.rank)")
                        .font(.headline.monospacedDigit())
                }
                ProgressView(value: context.state.progress)
                HStack {
                    Text("🔥 \(context.state.streak)")
                    Spacer()
                    Text("Score \(context.state.score)")
                }
                .font(.caption)
            }
            .padding(.vertical, 4)
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(.cyan)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("🔥 \(context.state.streak)")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("#\(context.state.rank)")
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("SkyCircuit Daily Run")
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                }
            } compactLeading: {
                Text("🚀")
            } compactTrailing: {
                Text("#\(context.state.rank)")
                    .font(.caption2)
            } minimal: {
                Text("🚀")
            }
        }
    }
}
