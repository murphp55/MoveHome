import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

/**
 * Posts a gesture event to the Home Assistant webhook.
 * Garmin does not have an MQTT library, so we use HTTP directly.
 *
 * POST {HA_BASE_URL}/api/webhook/{WEBHOOK_ID}
 * Body: { "gesture": "shake", "device": "garmin_watch" }
 */
class HttpPublisher {

    private var _baseUrl   as String;
    private var _webhookId as String;
    private var _deviceId  as String;

    function initialize(baseUrl as String, webhookId as String, deviceId as String) {
        _baseUrl   = baseUrl;
        _webhookId = webhookId;
        _deviceId  = deviceId;
    }

    function sendGesture(gesture as String) as Void {
        var url = _baseUrl + "/api/webhook/" + _webhookId;
        var params = {
            "gesture" => gesture,
            "device"  => _deviceId
        };
        var options = {
            :method  => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url, params, options, method(:onResponse));
    }

    function onResponse(responseCode as Number, data as Dictionary?) as Void {
        // Optionally handle errors (e.g. show a toast on failure)
        if (responseCode != 200 && responseCode != 204) {
            System.println("HttpPublisher error: " + responseCode);
        }
    }
}
