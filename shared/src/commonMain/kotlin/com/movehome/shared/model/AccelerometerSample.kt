package com.movehome.shared.model

import kotlin.math.sqrt

data class AccelerometerSample(
    val x: Float,
    val y: Float,
    val z: Float,
    val timestampMs: Long
) {
    val magnitude: Float get() = sqrt(x * x + y * y + z * z)
}
