import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;

/**
 * Glance view — visible by swiping up from the watch face.
 * Shows current capture status at a glance. Tapping launches the full app.
 *
 * DELETABLE: If the full app is removed, this glance can stand alone as
 * the only UI — it already calls toggleCapture() via the app delegate.
 */
(:glance)
class MoveHomeGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var app = Application.getApp() as MoveHomeApp;
        var capturing = app.isCapturing();

        var statusColor = capturing ? Graphics.COLOR_GREEN : Graphics.COLOR_LT_GRAY;
        var statusText  = capturing ? "Listening..." : "MoveHome";

        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_TINY,
            statusText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
