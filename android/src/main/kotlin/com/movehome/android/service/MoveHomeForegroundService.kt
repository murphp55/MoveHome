package com.movehome.android.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.movehome.android.CaptureState
import com.movehome.android.MainActivity
import com.movehome.android.sensor.AndroidAccelerometer
import com.movehome.android.widget.MoveHomeWidget
import com.movehome.shared.gesture.GestureRecognizer
import com.movehome.shared.sensor.SensorDataProcessor
import com.movehome.shared.smarthome.SmartHomeClient
import com.movehome.shared.smarthome.SmartHomeConfig
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Owns the full capture pipeline: sensor → filter → recognizer → HA webhook.
 * Runs as a foreground service so it survives app backgrounding.
 *
 * Controlled via startService() with one of the ACTION_* constants.
 * State is published to CaptureState so the UI, tile, and widget can observe it.
 *
 * DELETABLE UI NOTE: Once the Quick Settings tile and home screen widget are
 * the primary interaction points, MainActivity and MoveHomeViewModel can be
 * deleted. This service (and CaptureState) are the permanent core.
 */
class MoveHomeForegroundService : Service() {

    companion object {
        const val ACTION_START  = "com.movehome.START"
        const val ACTION_STOP   = "com.movehome.STOP"
        const val ACTION_TOGGLE = "com.movehome.TOGGLE"

        private const val CHANNEL_ID      = "movehome_capture"
        private const val NOTIFICATION_ID = 1
    }

    // Edit to match your Home Assistant instance
    private val config = SmartHomeConfig(
        haBaseUrl = "http://192.168.1.100:8123",
        webhookId = "movehome_android",
        deviceId  = "android_phone"
    )

    private val scope     = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val processor = SensorDataProcessor()
    private val recognizer = GestureRecognizer()
    private val haClient  by lazy { SmartHomeClient(config) }

    private lateinit var accelerometer: AndroidAccelerometer

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        accelerometer = AndroidAccelerometer(this) { raw ->
            if (!CaptureState.isCapturing.value) return@AndroidAccelerometer
            val filtered = processor.process(raw)
            val gesture  = recognizer.addSample(filtered) ?: return@AndroidAccelerometer
            CaptureState.setLastGesture(gesture)
            MoveHomeWidget.requestUpdate(this)
            scope.launch { runCatching { haClient.sendGesture(gesture) } }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START  -> if (!CaptureState.isCapturing.value) startCapture()
            ACTION_STOP   -> stopCapture()
            ACTION_TOGGLE -> if (CaptureState.isCapturing.value) stopCapture() else startCapture()
        }
        return START_NOT_STICKY
    }

    private fun startCapture() {
        recognizer.reset()
        processor.reset()
        CaptureState.setCapturing(true)
        MoveHomeWidget.requestUpdate(this)
        startForeground(NOTIFICATION_ID, buildNotification())
        accelerometer.start()
    }

    private fun stopCapture() {
        accelerometer.stop()
        CaptureState.setCapturing(false)
        MoveHomeWidget.requestUpdate(this)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun buildNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("MoveHome")
        .setContentText("Listening for gestures...")
        .setSmallIcon(android.R.drawable.ic_media_play)
        .setContentIntent(
            PendingIntent.getActivity(
                this, 0, Intent(this, MainActivity::class.java),
                PendingIntent.FLAG_IMMUTABLE
            )
        )
        .addAction(
            android.R.drawable.ic_media_pause, "Stop",
            PendingIntent.getService(
                this, 0,
                Intent(this, MoveHomeForegroundService::class.java).apply { action = ACTION_STOP },
                PendingIntent.FLAG_IMMUTABLE
            )
        )
        .build()

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID, "Gesture Capture", NotificationManager.IMPORTANCE_LOW
        ).apply { description = "Shown while MoveHome is capturing gestures" }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
