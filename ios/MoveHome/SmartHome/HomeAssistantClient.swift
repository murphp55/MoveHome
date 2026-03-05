import Foundation

struct SmartHomeConfig {
    let haBaseUrl: String   // e.g. "http://192.168.1.100:8123"
    let webhookId: String
    let deviceId: String
}

/// Sends gesture events to Home Assistant via webhook.
/// POST /api/webhook/{webhookId}  →  { "gesture": "shake", "device": "iphone" }
class HomeAssistantClient {
    private let config: SmartHomeConfig
    private let session = URLSession.shared

    init(config: SmartHomeConfig) {
        self.config = config
    }

    func sendGesture(_ gesture: String) {
        guard let url = URL(string: "\(config.haBaseUrl)/api/webhook/\(config.webhookId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["gesture": gesture, "device": config.deviceId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        session.dataTask(with: request).resume()
    }
}
