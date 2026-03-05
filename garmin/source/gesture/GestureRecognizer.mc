import Toybox.Lang;
import Toybox.Math;

/**
 * Direct Monkey C port of the shared KMP GestureRecognizer.
 * Mirrors the same algorithm: shake, tap, double-tap, tilt.
 *
 * Thresholds match shared/gesture/GestureRecognizer.kt
 */
class GestureRecognizer {

    private const WINDOW_SIZE      = 25;   // ~1 second at 25 Hz
    private const GRAVITY          = 9.81f;
    private const SHAKE_VARIANCE   = 3.0f;
    private const TAP_THRESHOLD    = 18.0f;
    private const DOUBLE_TAP_MS    = 400;
    private const TILT_FRACTION    = 0.65f;
    private const COOLDOWN_MS      = 500;
    private const MIN_SAMPLES      = 5;

    private var _windowX     as Array<Float>;
    private var _windowY     as Array<Float>;
    private var _windowZ     as Array<Float>;
    private var _windowTs    as Array<Number>;
    private var _windowMag   as Array<Float>;
    private var _count       as Number = 0;
    private var _lastGestureTs as Number = 0;

    function initialize() {
        _windowX   = new [WINDOW_SIZE]f;
        _windowY   = new [WINDOW_SIZE]f;
        _windowZ   = new [WINDOW_SIZE]f;
        _windowTs  = new [WINDOW_SIZE];
        _windowMag = new [WINDOW_SIZE]f;
    }

    function reset() as Void {
        _count = 0;
        _lastGestureTs = 0;
    }

    function addSample(x as Float, y as Float, z as Float, tsMs as Number) as String? {
        var idx = _count % WINDOW_SIZE;
        _windowX[idx]   = x;
        _windowY[idx]   = y;
        _windowZ[idx]   = z;
        _windowTs[idx]  = tsMs;
        _windowMag[idx] = Math.sqrt(x*x + y*y + z*z).toFloat();
        _count++;

        var size = _count < WINDOW_SIZE ? _count : WINDOW_SIZE;
        if (size < MIN_SAMPLES) { return null; }
        if (tsMs - _lastGestureTs < COOLDOWN_MS) { return null; }

        var gesture = classify(size);
        if (gesture != null) { _lastGestureTs = tsMs; }
        return gesture;
    }

    private function classify(size as Number) as String? {
        // --- Shake ---
        var sum = 0.0f;
        for (var i = 0; i < size; i++) { sum += _windowMag[i]; }
        var mean = sum / size;
        var varSum = 0.0f;
        for (var i = 0; i < size; i++) {
            var d = _windowMag[i] - mean;
            varSum += d * d;
        }
        var variance = varSum / size;
        if (variance > SHAKE_VARIANCE) { return "shake"; }

        // --- Tap / Double Tap ---
        var peaks = new [size];
        var peakCount = 0;
        for (var i = 1; i < size - 1; i++) {
            if (_windowMag[i] > TAP_THRESHOLD
                && _windowMag[i] > _windowMag[i-1]
                && _windowMag[i] > _windowMag[i+1]) {
                peaks[peakCount] = i;
                peakCount++;
            }
        }
        if (peakCount >= 2) {
            var i0 = peaks[0]; var i1 = peaks[1];
            var dt = _windowTs[i1] - _windowTs[i0];
            if (dt < DOUBLE_TAP_MS) { return "double_tap"; }
        }
        if (peakCount == 1) { return "tap"; }

        // --- Tilt (last 5 samples) ---
        var recentCount = size < 5 ? size : 5;
        var ax = 0.0f; var ay = 0.0f; var az = 0.0f;
        for (var i = size - recentCount; i < size; i++) {
            ax += _windowX[i]; ay += _windowY[i]; az += _windowZ[i];
        }
        ax /= recentCount; ay /= recentCount; az /= recentCount;
        var thresh = GRAVITY * TILT_FRACTION;

        if (az >  thresh) { return "tilt_up"; }
        if (az < -thresh) { return "tilt_down"; }
        if (ax >  thresh) { return "tilt_right"; }
        if (ax < -thresh) { return "tilt_left"; }
        if (ay >  thresh) { return "tilt_forward"; }
        if (ay < -thresh) { return "tilt_backward"; }

        return null;
    }
}
