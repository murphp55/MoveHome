package com.movehome.shared.model

enum class GestureType(val label: String) {
    SHAKE("shake"),
    TAP("tap"),
    DOUBLE_TAP("double_tap"),
    TILT_UP("tilt_up"),
    TILT_DOWN("tilt_down"),
    TILT_LEFT("tilt_left"),
    TILT_RIGHT("tilt_right"),
    TILT_FORWARD("tilt_forward"),
    TILT_BACKWARD("tilt_backward")
}
