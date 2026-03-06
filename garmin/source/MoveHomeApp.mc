import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class MoveHomeApp extends Application.AppBase {

    private var _view       as MoveHomeView?       = null;
    private var _recognizer as GestureRecognizer?  = null;
    private var _sensor     as GarminSensorManager? = null;
    private var _publisher  as HttpPublisher?       = null;
    private var _capturing  as Boolean              = false;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        _recognizer = new GestureRecognizer();
        _publisher  = new HttpPublisher(
            Rez.Strings.HA_BASE_URL,
            Rez.Strings.WEBHOOK_ID,
            Rez.Strings.DEVICE_ID
        );
        _sensor = new GarminSensorManager(_recognizer, method(:onGesture));

        // Schedule background service to run every 5 minutes
        Background.registerForTemporalEvent(new Time.Duration(5 * 60));
    }

    // Exposed for MoveHomeGlanceView to read without owning capture state
    function isCapturing() as Boolean {
        return _capturing;
    }

    function getBackgroundServiceDelegate() as System.ServiceDelegate {
        return new MoveHomeBackgroundService();
    }

    function onStop(state as Dictionary?) as Void {
        if (_capturing) {
            _sensor.stop();
        }
    }

    function getInitialView() as [ Views ] or [ Views, InputDelegates ] {
        var view = new MoveHomeView();
        _view = view;
        return [view, new MoveHomeDelegate(self)];
    }

    function toggleCapture() as Void {
        if (_capturing) {
            _sensor.stop();
            _capturing = false;
            _view.setStatus("Idle");
            _recognizer.reset();
        } else {
            _sensor.start();
            _capturing = true;
            _view.setStatus("Listening...");
        }
    }

    function onGesture(gesture as String) as Void {
        _view.setGesture(gesture.toString().replace("_", " ").toUpper());
        _publisher.sendGesture(gesture);
    }
}
