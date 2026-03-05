import Foundation
import Combine

// Import the KMP shared framework built via `./gradlew :shared:assembleXCFramework`
// and added to the Xcode project as Shared.xcframework.
import Shared

class MoveHomeViewModel: ObservableObject {

    // Edit these to match your Home Assistant instance
    private let haClient = HomeAssistantClient(config: SmartHomeConfig(
        haBaseUrl: "http://192.168.1.100:8123",
        webhookId: "movehome_ios",
        deviceId: "iphone"
    ))

    private let accelerometer = CoreMotionAccelerometer()
    private let processor = SensorDataProcessor()       // from Shared.xcframework
    private let recognizer = GestureRecognizer()        // from Shared.xcframework

    @Published var isCapturing = false
    @Published var lastGesture: String? = nil

    func toggleCapture() {
        isCapturing ? stopCapture() : startCapture()
    }

    func setupBackTap() {
        // Wire this up in SceneDelegate / Info.plist URL scheme "movehome://trigger"
        NotificationCenter.default.addObserver(
            forName: .init("MoveHomeBackTap"),
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.toggleCapture() }
    }

    private func startCapture() {
        isCapturing = true
        recognizer.reset()
        processor.reset()
        accelerometer.start { [weak self] x, y, z, ts in
            guard let self else { return }
            let raw = AccelerometerSample(x: x, y: y, z: z, timestampMs: ts)
            let filtered = self.processor.process(raw: raw)
            guard let gesture = self.recognizer.addSample(sample: filtered) else { return }
            DispatchQueue.main.async {
                self.lastGesture = gesture.label
                self.haClient.sendGesture(gesture.label)
            }
        }
    }

    private func stopCapture() {
        isCapturing = false
        accelerometer.stop()
    }
}
