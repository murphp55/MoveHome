package com.movehome.android

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.movehome.android.sensor.AndroidAccelerometer
import com.movehome.shared.gesture.GestureRecognizer
import com.movehome.shared.model.GestureType
import com.movehome.shared.sensor.SensorDataProcessor
import com.movehome.shared.smarthome.SmartHomeClient
import com.movehome.shared.smarthome.SmartHomeConfig
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class MoveHomeViewModel(app: Application) : AndroidViewModel(app) {

    // Edit these to match your Home Assistant instance
    private val config = SmartHomeConfig(
        haBaseUrl = "http://192.168.1.100:8123",
        webhookId = "movehome_android",
        deviceId = "android_phone"
    )

    private val processor = SensorDataProcessor()
    private val recognizer = GestureRecognizer()
    private val smartHomeClient = SmartHomeClient(config)

    private val _lastGesture = MutableStateFlow<GestureType?>(null)
    val lastGesture: StateFlow<GestureType?> = _lastGesture

    private val _isCapturing = MutableStateFlow(false)
    val isCapturing: StateFlow<Boolean> = _isCapturing

    val accelerometer = AndroidAccelerometer(app) { raw ->
        if (!_isCapturing.value) return@AndroidAccelerometer
        val filtered = processor.process(raw)
        val gesture = recognizer.addSample(filtered) ?: return@AndroidAccelerometer
        _lastGesture.value = gesture
        viewModelScope.launch {
            runCatching { smartHomeClient.sendGesture(gesture) }
        }
    }

    fun toggleCapture() {
        if (_isCapturing.value) {
            _isCapturing.value = false
            accelerometer.stop()
            recognizer.reset()
            processor.reset()
        } else {
            _isCapturing.value = true
            accelerometer.start()
        }
    }

    fun onVolumeDown() = toggleCapture()

    override fun onCleared() {
        accelerometer.stop()
        smartHomeClient.close()
    }
}
