import CoreMotion
import Foundation

typealias SampleHandler = (Float, Float, Float, Int64) -> Void

/// Wraps CMMotionManager to deliver accelerometer samples at ~50 Hz.
class CoreMotionAccelerometer {
    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 50.0  // 50 Hz

    var isAvailable: Bool { motionManager.isAccelerometerAvailable }

    func start(onSample: @escaping SampleHandler) {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            guard let data else { return }
            // CoreMotion reports in g-force; convert to m/s²
            let g: Double = 9.81
            let x = Float(data.acceleration.x * g)
            let y = Float(data.acceleration.y * g)
            let z = Float(data.acceleration.z * g)
            let ts = Int64(data.timestamp * 1000)
            onSample(x, y, z, ts)
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}
