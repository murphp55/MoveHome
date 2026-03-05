import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MoveHomeViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text(viewModel.isCapturing ? "Listening..." : "Idle")
                .font(.title)

            Text(viewModel.lastGesture?.replacingOccurrences(of: "_", with: " ").uppercased() ?? "—")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.accentColor)

            Button(viewModel.isCapturing ? "Stop" : "Start") {
                viewModel.toggleCapture()
            }
            .buttonStyle(.borderedProminent)
            .font(.title2)

            Text("Or use Back Tap (Settings > Accessibility > Touch > Back Tap)")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .onAppear { viewModel.setupBackTap() }
    }
}
