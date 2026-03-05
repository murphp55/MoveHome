import Toybox.Sensor;
import Toybox.Lang;

/**
 * Registers for accelerometer data at ~25 Hz and forwards samples
 * to GestureRecognizer. Garmin's minimum period is typically 40ms (25 Hz).
 */
class GarminSensorManager {

    private var _recognizer as GestureRecognizer;
    private var _onGesture as Method;

    function initialize(recognizer as GestureRecognizer, onGesture as Method) {
        _recognizer = recognizer;
        _onGesture = onGesture;
    }

    function start() as Void {
        var options = {
            :period    => 1,        // sample every 1/25 second
            :accelerometer => {
                :enabled => true,
                :sampleRate => 25   // Hz — supported on most devices
            }
        };
        Sensor.registerSensorDataListener(method(:onData), options);
    }

    function stop() as Void {
        Sensor.unregisterSensorDataListener();
    }

    function onData(sensorData as Sensor.SensorData) as Void {
        var accel = sensorData.accelerometerData;
        if (accel == null) { return; }

        var xs = accel.x;
        var ys = accel.y;
        var zs = accel.z;
        if (xs == null || ys == null || zs == null) { return; }

        // Garmin reports in milli-g; convert to m/s²
        var g = 9.81f;
        var scale = g / 1000.0f;

        var tsMs = sensorData.when.value();

        for (var i = 0; i < xs.size(); i++) {
            var x = xs[i] * scale;
            var y = ys[i] * scale;
            var z = zs[i] * scale;
            var gesture = _recognizer.addSample(x, y, z, tsMs + i * 40);
            if (gesture != null) {
                _onGesture.invoke(gesture);
            }
        }
    }
}
