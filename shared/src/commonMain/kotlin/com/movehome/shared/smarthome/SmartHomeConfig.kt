package com.movehome.shared.smarthome

import kotlinx.serialization.Serializable

/**
 * Configuration for the Home Assistant connection.
 *
 * haBaseUrl  - e.g. "http://192.168.1.100:8123"
 * webhookId  - the HA webhook ID created under Settings > Automations
 * deviceId   - a label for the sending device (e.g. "android_phone", "garmin_watch")
 */
@Serializable
data class SmartHomeConfig(
    val haBaseUrl: String,
    val webhookId: String,
    val deviceId: String
)
