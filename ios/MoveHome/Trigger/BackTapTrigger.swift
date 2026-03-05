import Foundation

/// Back Tap is configured by the user in iOS Settings:
///   Settings > Accessibility > Touch > Back Tap > Double Tap (or Triple Tap)
///   → assign a custom action / Shortcut that calls a URL scheme.
///
/// Register a URL scheme "movehome://trigger" in Info.plist and handle it here.
///
/// Alternatively, use a Shortcut automation that fires an HTTP request directly
/// to Home Assistant — no app code needed in that case.
class BackTapTrigger {

    static let urlScheme = "movehome"
    static let triggerAction = "trigger"

    /// Returns true if the URL is a back-tap trigger. Call from scene(_:openURLContexts:).
    static func handle(url: URL, onTrigger: () -> Void) -> Bool {
        guard url.scheme == urlScheme, url.host == triggerAction else { return false }
        onTrigger()
        return true
    }
}
