package com.movehome.android.sensor

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import com.movehome.shared.model.AccelerometerSample

/**
 * Wraps Android SensorManager to deliver AccelerometerSamples at ~50 Hz.
 * Call [start] to begin listening, [stop] to release the sensor.
 */
class AndroidAccelerometer(
    context: Context,
    private val onSample: (AccelerometerSample) -> Unit
) : SensorEventListener {

    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer =
        sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    fun start() {
        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        }
    }

    fun stop() {
        sensorManager.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return
        onSample(
            AccelerometerSample(
                x = event.values[0],
                y = event.values[1],
                z = event.values[2],
                timestampMs = event.timestamp / 1_000_000L
            )
        )
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) = Unit
}
