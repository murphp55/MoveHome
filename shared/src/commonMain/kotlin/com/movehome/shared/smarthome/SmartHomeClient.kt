package com.movehome.shared.smarthome

import com.movehome.shared.model.GestureType
import io.ktor.client.HttpClient
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

@Serializable
private data class GesturePayload(val gesture: String, val device: String)

/**
 * Sends detected gestures to Home Assistant via its webhook API.
 *
 * In Home Assistant, create an automation with trigger type "Webhook" and
 * set the webhook ID to match [SmartHomeConfig.webhookId].
 *
 * POST  /api/webhook/{webhookId}
 * Body: { "gesture": "shake", "device": "android_phone" }
 */
class SmartHomeClient(private val config: SmartHomeConfig) {

    private val client = HttpClient {
        install(ContentNegotiation) {
            json(Json { ignoreUnknownKeys = true })
        }
    }

    suspend fun sendGesture(gesture: GestureType) {
        val url = "${config.haBaseUrl}/api/webhook/${config.webhookId}"
        client.post(url) {
            contentType(ContentType.Application.Json)
            setBody(GesturePayload(gesture.label, config.deviceId))
        }
    }

    fun close() = client.close()
}
