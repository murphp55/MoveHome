package com.movehome.android.tile

import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import com.movehome.android.CaptureState
import com.movehome.android.service.MoveHomeForegroundService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

/**
 * Quick Settings tile — swipe down the notification shade and tap to toggle capture.
 * No app UI opens. Works from the lock screen.
 *
 * To add the tile: long-press the notification shade → Edit → drag MoveHome into position.
 */
@RequiresApi(Build.VERSION_CODES.N)
class MoveHomeTileService : TileService() {

    private val scope = CoroutineScope(Dispatchers.Main)
    private var job: Job? = null

    override fun onStartListening() {
        // Sync tile state with CaptureState while the tile panel is visible
        job = CaptureState.isCapturing
            .onEach { syncTile(it) }
            .launchIn(scope)
    }

    override fun onStopListening() {
        job?.cancel()
    }

    override fun onClick() {
        startService(
            Intent(this, MoveHomeForegroundService::class.java)
                .apply { action = MoveHomeForegroundService.ACTION_TOGGLE }
        )
    }

    private fun syncTile(capturing: Boolean) {
        val tile = qsTile ?: return
        tile.state    = if (capturing) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label    = "MoveHome"
        tile.subtitle = if (capturing) "Listening" else "Idle"
        tile.updateTile()
    }
}
