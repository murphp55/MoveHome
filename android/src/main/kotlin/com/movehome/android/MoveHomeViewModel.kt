package com.movehome.android

import android.app.Application
import android.content.Intent
import androidx.lifecycle.AndroidViewModel
import com.movehome.android.service.MoveHomeForegroundService
import com.movehome.shared.model.GestureType
import kotlinx.coroutines.flow.StateFlow

/**
 * Thin UI adapter over MoveHomeForegroundService + CaptureState.
 *
 * DELETABLE: Once the Quick Settings tile and home screen widget are the
 * primary interaction points, this ViewModel and MainActivity can be removed.
 * MoveHomeForegroundService + CaptureState are the permanent core.
 */
class MoveHomeViewModel(private val app: Application) : AndroidViewModel(app) {

    val isCapturing: StateFlow<Boolean>    = CaptureState.isCapturing
    val lastGesture: StateFlow<GestureType?> = CaptureState.lastGesture

    fun toggleCapture() = sendAction(MoveHomeForegroundService.ACTION_TOGGLE)
    fun onVolumeDown()  = sendAction(MoveHomeForegroundService.ACTION_TOGGLE)

    private fun sendAction(action: String) {
        app.startService(
            Intent(app, MoveHomeForegroundService::class.java).apply { this.action = action }
        )
    }
}
