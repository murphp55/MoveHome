package com.movehome.android

import com.movehome.shared.model.GestureType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Single source of truth for capture state, shared between:
 *   - MoveHomeForegroundService (writes)
 *   - MoveHomeViewModel         (reads → UI)
 *   - MoveHomeTileService       (reads → tile)
 *   - MoveHomeWidget            (reads → widget)
 *
 * Lives in-process; no IPC needed because the service, tile, and widget
 * all run in the same app process.
 */
object CaptureState {

    private val _isCapturing = MutableStateFlow(false)
    val isCapturing: StateFlow<Boolean> = _isCapturing

    private val _lastGesture = MutableStateFlow<GestureType?>(null)
    val lastGesture: StateFlow<GestureType?> = _lastGesture

    fun setCapturing(value: Boolean) { _isCapturing.value = value }
    fun setLastGesture(gesture: GestureType) { _lastGesture.value = gesture }
}
