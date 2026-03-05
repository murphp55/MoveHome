package com.movehome.shared.sensor

import com.movehome.shared.model.AccelerometerSample

/**
 * Applies a low-pass filter to smooth raw accelerometer data and reduce noise.
 * Alpha controls the smoothing: lower = more smoothing, higher = more responsive.
 */
class SensorDataProcessor(private val alpha: Float = 0.15f) {

    private var filteredX = 0f
    private var filteredY = 0f
    private var filteredZ = 0f
    private var initialized = false

    fun process(raw: AccelerometerSample): AccelerometerSample {
        if (!initialized) {
            filteredX = raw.x
            filteredY = raw.y
            filteredZ = raw.z
            initialized = true
        } else {
            filteredX = alpha * raw.x + (1f - alpha) * filteredX
            filteredY = alpha * raw.y + (1f - alpha) * filteredY
            filteredZ = alpha * raw.z + (1f - alpha) * filteredZ
        }
        return AccelerometerSample(filteredX, filteredY, filteredZ, raw.timestampMs)
    }

    fun reset() {
        initialized = false
    }
}
