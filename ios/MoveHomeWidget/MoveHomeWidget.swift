import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline entry

struct MoveHomeEntry: TimelineEntry {
    let date: Date
    let isCapturing: Bool
    let lastGesture: String?
}

// MARK: - Provider

/**
 * Reads state from the shared App Group UserDefaults written by CaptureState.
 * CaptureState.notifyWidget() calls WidgetCenter.reloadAllTimelines() after
 * each state change, so the widget stays current without polling.
 */
struct MoveHomeProvider: TimelineProvider {

    private static let suiteName = "group.com.movehome"

    func placeholder(in context: Context) -> MoveHomeEntry {
        MoveHomeEntry(date: .now, isCapturing: false, lastGesture: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MoveHomeEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoveHomeEntry>) -> Void) {
        // Policy .never means we only refresh when explicitly told to (via reloadAllTimelines)
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> MoveHomeEntry {
        let defaults    = UserDefaults(suiteName: Self.suiteName) ?? .standard
        let capturing   = defaults.bool(forKey: "isCapturing")
        let lastGesture = defaults.string(forKey: "lastGesture")
        return MoveHomeEntry(date: .now, isCapturing: capturing, lastGesture: lastGesture)
    }
}

// MARK: - Widget view

struct MoveHomeWidgetView: View {

    let entry: MoveHomeEntry

    var body: some View {
        VStack(spacing: 6) {
            Text(entry.isCapturing ? "Listening..." : "Idle")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(entry.lastGesture?.replacingOccurrences(of: "_", with: " ").uppercased() ?? "—")
                .font(.headline)
                .minimumScaleFactor(0.7)

            Button(intent: ToggleCaptureIntent()) {
                Label(
                    entry.isCapturing ? "Stop" : "Start",
                    systemImage: entry.isCapturing ? "stop.circle.fill" : "play.circle.fill"
                )
                .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.mini)
            .tint(entry.isCapturing ? .red : .accentColor)
        }
        .padding(10)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget configuration

struct MoveHomeWidget: Widget {

    static let kind = "MoveHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: MoveHomeProvider()) { entry in
            MoveHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("MoveHome")
        .description("Toggle gesture capture from your home screen or Lock Screen.")
        .supportedFamilies([
            .systemSmall,           // home screen
            .accessoryCircular,     // lock screen circular
            .accessoryRectangular,  // lock screen rectangular
            .accessoryInline        // lock screen inline
        ])
    }
}
