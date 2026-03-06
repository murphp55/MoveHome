import Foundation
import Shared   // KMP XCFramework

/**
 * Owns the full capture pipeline: CoreMotion → filter → recognizer → HA webhook.
 * Singleton so it can be used from the app, AppIntents, and background tasks
 * without creating duplicate sensor sessions.
 *
 * DELETABLE UI NOTE: Once AppIntents + WidgetKit are the primary interaction
 * points, ContentView, MoveHomeViewModel, and MoveHomeApp can all be removed.
 * CaptureManager, CaptureState, MoveHomeIntent, and MoveHomeWidget remain.
 */
class CaptureManager {

    static let shared = CaptureManager()

    // Edit to match your Home Assistant instance
    private let haClient = HomeAssistantClient(config: SmartHomeConfig(
        haBaseUrl: "http://192.168.1.100:8123",
        webhookId: "movehome_ios",
        deviceId:  "iphone"
    ))

    private let accelerometer = CoreMotionAccelerometer()
    private let processor     = SensorDataProcessor()   // from Shared.xcframework
    private let recognizer    = GestureRecognizer()     // from Shared.xcframework

    /// Optional callback for the UI to observe gestures without polling CaptureState.
    var onGestureDetected: ((String) -> Void)?

    private init() {}

    func toggle() {
        CaptureState.shared.isCapturing ? stop() : start()
    }

    func start() {
        guard !CaptureState.shared.isCapturing else { return }
        CaptureState.shared.isCapturing = true
        recognizer.reset()
        processor.reset()
        accelerometer.start { [weak self] x, y, z, ts in
            guard let self else { return }
            let raw      = AccelerometerSample(x: x, y: y, z: z, timestampMs: ts)
            let filtered = self.processor.process(raw: raw)
            guard let gesture = self.recognizer.addSample(sample: filtered) else { return }
            DispatchQueue.main.async {
                CaptureState.shared.lastGesture = gesture.label
                self.onGestureDetected?(gesture.label)
                self.haClient.sendGesture(gesture.label)
            }
        }
    }

    func stop() {
        CaptureState.shared.isCapturing = false
        accelerometer.stop()
    }
}
