package com.movehome.shared.gesture

import com.movehome.shared.model.AccelerometerSample
import com.movehome.shared.model.GestureType
import kotlin.math.sqrt

/**
 * Sliding-window gesture recognizer.
 *
 * Detects:
 *   SHAKE       - high variance in magnitude over the window
 *   TAP         - single sharp magnitude spike
 *   DOUBLE_TAP  - two peaks within DOUBLE_TAP_WINDOW_MS
 *   TILT_*      - sustained gravity component along an axis
 *
 * Feed samples at ~50 Hz via [addSample]. Returns a [GestureType] when one is
 * detected, or null otherwise. A cooldown prevents repeated firing.
 */
class GestureRecognizer(
    sampleRateHz: Int = 50,
    windowDurationSec: Float = 1.0f
) {
    private val windowSize = (sampleRateHz * windowDurationSec).toInt()
    private val window = ArrayDeque<AccelerometerSample>(windowSize)
    private var lastGestureTimeMs = 0L

    companion object {
        const val GRAVITY = 9.81f
        const val SHAKE_VARIANCE_THRESHOLD = 3.0f   // (m/s²)²
        const val TAP_PEAK_THRESHOLD = 18.0f         // m/s²
        const val DOUBLE_TAP_WINDOW_MS = 400L
        const val TILT_FRACTION = 0.65f              // fraction of g to consider a tilt
        const val COOLDOWN_MS = 500L
        const val MIN_SAMPLES = 10
    }

    fun addSample(sample: AccelerometerSample): GestureType? {
        window.addLast(sample)
        if (window.size > windowSize) window.removeFirst()
        if (window.size < MIN_SAMPLES) return null

        val now = sample.timestampMs
        if (now - lastGestureTimeMs < COOLDOWN_MS) return null

        return classify(window.toList())?.also { lastGestureTimeMs = now }
    }

    fun reset() {
        window.clear()
        lastGestureTimeMs = 0L
    }

    private fun classify(samples: List<AccelerometerSample>): GestureType? {
        val magnitudes = samples.map { it.magnitude }
        val mean = magnitudes.average().toFloat()
        val variance = magnitudes.map { d -> (d - mean) * (d - mean) }.average().toFloat()

        if (variance > SHAKE_VARIANCE_THRESHOLD) return GestureType.SHAKE

        val peaks = findPeaks(magnitudes, TAP_PEAK_THRESHOLD)
        if (peaks.size >= 2) {
            val dt = samples[peaks[1]].timestampMs - samples[peaks[0]].timestampMs
            if (dt < DOUBLE_TAP_WINDOW_MS) return GestureType.DOUBLE_TAP
        }
        if (peaks.size == 1) return GestureType.TAP

        // Tilt: check sustained gravity direction in the last 10 samples
        val recent = samples.takeLast(10)
        val avgX = recent.map { it.x }.average().toFloat()
        val avgY = recent.map { it.y }.average().toFloat()
        val avgZ = recent.map { it.z }.average().toFloat()
        val threshold = GRAVITY * TILT_FRACTION

        return when {
            avgZ >  threshold -> GestureType.TILT_UP
            avgZ < -threshold -> GestureType.TILT_DOWN
            avgX >  threshold -> GestureType.TILT_RIGHT
            avgX < -threshold -> GestureType.TILT_LEFT
            avgY >  threshold -> GestureType.TILT_FORWARD
            avgY < -threshold -> GestureType.TILT_BACKWARD
            else -> null
        }
    }

    private fun findPeaks(values: List<Float>, threshold: Float): List<Int> =
        (1 until values.size - 1).filter { i ->
            values[i] > threshold && values[i] > values[i - 1] && values[i] > values[i + 1]
        }
}
