import Foundation
import Combine

/**
 * Thin UI adapter over CaptureManager + CaptureState.
 *
 * DELETABLE: Once the Action Button intent and home/lock screen widget are the
 * primary interaction points, this ViewModel, ContentView, and MoveHomeApp
 * can all be removed. CaptureManager + CaptureState are the permanent core.
 */
class MoveHomeViewModel: ObservableObject {

    @Published var isCapturing: Bool    = CaptureState.shared.isCapturing
    @Published var lastGesture: String? = CaptureState.shared.lastGesture

    private var cancellables = Set<AnyCancellable>()

    init() {
        CaptureManager.shared.onGestureDetected = { [weak self] gesture in
            self?.lastGesture = gesture
        }
        CaptureState.shared.$isCapturing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isCapturing)
        CaptureState.shared.$lastGesture
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastGesture)
    }

    func toggleCapture() {
        CaptureManager.shared.toggle()
    }

    func setupBackTap() {
        NotificationCenter.default.addObserver(
            forName: .init("MoveHomeBackTap"),
            object: nil,
            queue: .main
        ) { [weak self] _ in self?.toggleCapture() }
    }
}
