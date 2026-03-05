import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class MoveHomeView extends WatchUi.View {

    private var _status   as String = "Idle";
    private var _gesture  as String = "---";

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(cx, cy - 40, Graphics.FONT_MEDIUM, _status,
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy + 10, Graphics.FONT_LARGE, _gesture,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    function setStatus(status as String) as Void {
        _status = status;
        WatchUi.requestUpdate();
    }

    function setGesture(gesture as String) as Void {
        _gesture = gesture;
        WatchUi.requestUpdate();
    }
}

class MoveHomeDelegate extends WatchUi.BehaviorDelegate {

    private var _app as MoveHomeApp;

    function initialize(app as MoveHomeApp) {
        BehaviorDelegate.initialize();
        _app = app;
    }

    // Any watch button press toggles capture
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        _app.toggleCapture();
        return true;
    }
}
