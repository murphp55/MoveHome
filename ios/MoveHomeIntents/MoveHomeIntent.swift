import AppIntents
import Foundation

/**
 * AppIntents that can be triggered by:
 *   - Action Button (iPhone 15 Pro+ / iPhone 16): Settings > Action Button > Shortcut
 *   - Siri: "Hey Siri, toggle MoveHome"
 *   - Shortcuts app: build custom automations
 *   - Lock Screen widget button
 *   - Back Tap (via a Shortcut that runs this intent)
 *
 * These intents perform in-process when the app is in the background.
 * The app must have Background Processing or Background App Refresh enabled
 * in Xcode (Signing & Capabilities > Background Modes) for sensor access
 * to continue after the intent fires.
 */

// MARK: - Toggle (Action Button primary intent)

struct ToggleCaptureIntent: AppIntent {

    static var title: LocalizedStringResource = "Toggle MoveHome"
    static var description = IntentDescription(
        "Start gesture capture if idle, stop it if already running."
    )
    /// Surfaces in the Action Button picker and Shortcuts app
    static var isDiscoverable = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run { CaptureManager.shared.toggle() }
        let dialog = CaptureState.shared.isCapturing ? "MoveHome is listening." : "MoveHome stopped."
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

// MARK: - Explicit start / stop (useful for Shortcuts automations)

struct StartCaptureIntent: AppIntent {

    static var title: LocalizedStringResource = "Start MoveHome"
    static var description = IntentDescription("Begin gesture capture.")
    static var isDiscoverable = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run { CaptureManager.shared.start() }
        return .result(dialog: "MoveHome is now listening.")
    }
}

struct StopCaptureIntent: AppIntent {

    static var title: LocalizedStringResource = "Stop MoveHome"
    static var description = IntentDescription("Stop gesture capture.")
    static var isDiscoverable = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run { CaptureManager.shared.stop() }
        return .result(dialog: "MoveHome stopped.")
    }
}

// MARK: - App Shortcuts (exposes to Siri without user setup)

struct MoveHomeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleCaptureIntent(),
            phrases: ["Toggle \(.applicationName)", "Start \(.applicationName)", "Stop \(.applicationName)"],
            shortTitle: "Toggle MoveHome",
            systemImageName: "wave.3.right"
        )
    }
}
