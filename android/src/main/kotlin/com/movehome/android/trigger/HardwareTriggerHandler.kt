package com.movehome.android.trigger

import android.view.KeyEvent

/**
 * Detects volume-down long-press or power-button press as a hardware trigger
 * to start/stop gesture capture.
 *
 * Wire this into Activity.onKeyDown.
 */
class HardwareTriggerHandler(private val onTrigger: () -> Unit) {

    fun onKeyDown(keyCode: Int): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                onTrigger()
                true
            }
            else -> false
        }
    }
}
