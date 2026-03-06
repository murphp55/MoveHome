package com.movehome.android.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.movehome.android.CaptureState
import com.movehome.android.R
import com.movehome.android.service.MoveHomeForegroundService

/**
 * Home screen widget — tap anywhere on the widget to toggle capture.
 * Shows current status and last detected gesture.
 *
 * To add: long-press the home screen → Widgets → MoveHome.
 */
class MoveHomeWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { update(context, manager, it) }
    }

    companion object {
        /** Called from MoveHomeForegroundService after each state change. */
        fun requestUpdate(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, MoveHomeWidget::class.java))
            if (ids.isEmpty()) return
            MoveHomeWidget().onUpdate(context, manager, ids)
        }

        private fun update(context: Context, manager: AppWidgetManager, widgetId: Int) {
            val capturing = CaptureState.isCapturing.value
            val gesture   = CaptureState.lastGesture.value
                ?.label?.replace('_', ' ')?.uppercase() ?: "—"

            val views = RemoteViews(context.packageName, R.layout.widget_movehome)
            views.setTextViewText(R.id.widget_status, if (capturing) "Listening..." else "Idle")
            views.setTextViewText(R.id.widget_gesture, gesture)

            val toggleIntent = PendingIntent.getService(
                context, 0,
                Intent(context, MoveHomeForegroundService::class.java)
                    .apply { action = MoveHomeForegroundService.ACTION_TOGGLE },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, toggleIntent)
            manager.updateAppWidget(widgetId, views)
        }
    }
}
