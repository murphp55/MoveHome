package com.movehome.android

import android.os.Bundle
import android.view.KeyEvent
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle

class MainActivity : ComponentActivity() {

    private val viewModel: MoveHomeViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { MoveHomeScreen(viewModel) }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (viewModel.accelerometer.let { false } ) return super.onKeyDown(keyCode, event)
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            viewModel.onVolumeDown()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}

@Composable
fun MoveHomeScreen(viewModel: MoveHomeViewModel) {
    val isCapturing by viewModel.isCapturing.collectAsStateWithLifecycle()
    val lastGesture by viewModel.lastGesture.collectAsStateWithLifecycle()

    MaterialTheme {
        Surface(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier.fillMaxSize().padding(24.dp),
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = if (isCapturing) "Listening..." else "Idle",
                    style = MaterialTheme.typography.headlineMedium
                )

                Spacer(Modifier.height(16.dp))

                Text(
                    text = lastGesture?.label?.replace('_', ' ')?.uppercase() ?: "—",
                    style = MaterialTheme.typography.displaySmall,
                    color = MaterialTheme.colorScheme.primary
                )

                Spacer(Modifier.height(32.dp))

                Button(onClick = { viewModel.toggleCapture() }) {
                    Text(if (isCapturing) "Stop" else "Start")
                }

                Spacer(Modifier.height(8.dp))

                Text(
                    text = "Or press Volume Down to toggle",
                    style = MaterialTheme.typography.bodySmall
                )
            }
        }
    }
}
