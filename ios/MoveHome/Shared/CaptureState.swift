import Foundation
import Combine

/**
 * Shared state between the app, AppIntents, and the WidgetKit extension.
 *
 * Uses UserDefaults backed by an App Group so the widget process can read it.
 * App Group ID must be configured in Xcode:
 *   Target > Signing & Capabilities > + Capability > App Groups → "group.com.movehome"
 * Apply the same group to the widget extension target.
 */
class CaptureState: ObservableObject {

    static let shared = CaptureState()

    private static let suiteName = "group.com.movehome"
    private let defaults: UserDefaults

    @Published var isCapturing: Bool {
        didSet {
            defaults.set(isCapturing, forKey: "isCapturing")
            notifyWidget()
        }
    }

    @Published var lastGesture: String? {
        didSet {
            defaults.set(lastGesture, forKey: "lastGesture")
            notifyWidget()
        }
    }

    private init() {
        defaults = UserDefaults(suiteName: Self.suiteName) ?? .standard
        isCapturing = defaults.bool(forKey: "isCapturing")
        lastGesture = defaults.string(forKey: "lastGesture")
    }

    private func notifyWidget() {
        // Tells WidgetKit to reload its timeline so the widget reflects new state
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
