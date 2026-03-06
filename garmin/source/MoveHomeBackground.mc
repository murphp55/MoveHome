import Toybox.Background;
import Toybox.Communications;
import Toybox.Application;
import Toybox.System;

/**
 * Background service — runs on a schedule (every 5 min, set in MoveHomeApp.onStart)
 * even when the watch app is closed.
 *
 * IMPORTANT LIMITATION: Connect IQ does not allow continuous accelerometer
 * access from a background service. Sensor data is limited to 1 Hz here,
 * which is insufficient for live gesture recognition.
 *
 * Use cases for this service:
 *   - Scheduled "I'm home" / "leaving home" triggers based on time
 *   - Sending a heartbeat to HA so it knows the watch is active
 *   - Triggering a fixed automation on a timer (not gesture-based)
 *
 * For live gesture detection, the foreground watch app (MoveHomeApp) is required.
 */
(:background)
class MoveHomeBackgroundService extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var haUrl     = Application.loadResource(Rez.Strings.HA_BASE_URL) as String;
        var webhookId = Application.loadResource(Rez.Strings.WEBHOOK_ID) as String;
        var deviceId  = Application.loadResource(Rez.Strings.DEVICE_ID) as String;

        Communications.makeWebRequest(
            haUrl + "/api/webhook/" + webhookId,
            { "gesture" => "background_ping", "device" => deviceId },
            {
                :method  => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON }
            },
            method(:onResponse)
        );
    }

    function onResponse(responseCode as Number, data as Dictionary?) as Void {
        // Nothing to handle — fire and forget
    }
}
