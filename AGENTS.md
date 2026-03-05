# MoveHome — Agent Reference

## Project Summary
MoveHome captures accelerometer data from a device (phone or watch) and uses it for gesture recognition that triggers smart home automations via Home Assistant webhooks.

## Architecture

### Cross-Platform Strategy
- **Android + iOS**: Kotlin Multiplatform (KMP). Business logic lives in `:shared` and is consumed by both platforms.
- **Garmin**: Cannot use KMP. The gesture algorithm in `garmin/source/gesture/GestureRecognizer.mc` is a manual port of the shared Kotlin logic and must be kept in sync manually.

### Shared Module (`shared/`)
Language: Kotlin (commonMain, androidMain, iosMain)

| File | Purpose |
|------|---------|
| `model/AccelerometerSample.kt` | Data class: x, y, z (m/s²), timestampMs, magnitude |
| `model/GestureType.kt` | Enum of all recognized gestures |
| `sensor/SensorDataProcessor.kt` | Low-pass filter. alpha=0.15 by default |
| `gesture/GestureRecognizer.kt` | Sliding window classifier (50 Hz, 1s window) |
| `smarthome/SmartHomeConfig.kt` | haBaseUrl, webhookId, deviceId |
| `smarthome/SmartHomeClient.kt` | Ktor POST to HA webhook |

HTTP engine is resolved automatically: `ktor-client-okhttp` on Android, `ktor-client-darwin` on iOS — no expect/actual needed.

### Android (`android/`)
Language: Kotlin + Jetpack Compose

- `AndroidAccelerometer.kt` — wraps `SensorManager`, SENSOR_DELAY_GAME (~50 Hz)
- `MoveHomeViewModel.kt` — owns lifecycle, wires sensor → processor → recognizer → HA client
- `MainActivity.kt` — Compose UI + volume-down key handler
- Sensor values from Android are already in m/s², no conversion needed

### iOS (`ios/MoveHome/`)
Language: Swift + SwiftUI

- `CoreMotionAccelerometer.swift` — wraps CMMotionManager at 50 Hz. CoreMotion reports in **g-force**; multiply by 9.81 to get m/s² before passing to KMP
- `MoveHomeViewModel.swift` — imports `Shared.xcframework` built from the KMP module
- `HomeAssistantClient.swift` — uses URLSession directly (does not use KMP SmartHomeClient)
- `BackTapTrigger.swift` — handles `movehome://trigger` URL scheme for iOS Back Tap

To build the XCFramework: `./gradlew :shared:assembleXCFramework`
Output: `shared/build/XCFrameworks/release/Shared.xcframework`

### Garmin (`garmin/`)
Language: Monkey C (Connect IQ)

- App type: `watchApp`
- Sensor data arrives in **milli-g**; multiply by `9.81 / 1000.0` to get m/s²
- HTTP via `Communications.makeWebRequest` (no MQTT library available)
- `manifest.xml` lists supported devices; add more `<iq:product>` entries as needed
- Configuration (HA URL, webhook ID, device ID) is in `garmin/resources/resources.xml`

## Gesture Recognition Algorithm

All platforms implement the same logic (shared in Kotlin, ported in Monkey C):

1. Maintain a sliding window of ~1 second of samples
2. Compute magnitude = sqrt(x²+y²+z²) for each sample
3. Classify in order:
   - **SHAKE**: window magnitude variance > 3.0 (m/s²)²
   - **DOUBLE_TAP**: ≥2 peaks above 18 m/s², separated by <400 ms
   - **TAP**: exactly 1 peak above 18 m/s²
   - **TILT_\***: sustained gravity component along an axis (avg > 0.65g)
4. Cooldown of 500 ms between gestures

**Tuning constants** (same values in both Kotlin and Monkey C):
| Constant | Value | File |
|----------|-------|------|
| SHAKE_VARIANCE_THRESHOLD | 3.0 | `GestureRecognizer.kt` / `.mc` |
| TAP_PEAK_THRESHOLD | 18.0 m/s² | same |
| DOUBLE_TAP_WINDOW_MS | 400 | same |
| TILT_FRACTION | 0.65 | same |
| COOLDOWN_MS | 500 | same |

When adjusting thresholds, update **both** files.

## Home Assistant Integration

All platforms POST to:
```
POST {haBaseUrl}/api/webhook/{webhookId}
Content-Type: application/json
{ "gesture": "shake", "device": "android_phone" }
```

In Home Assistant: Settings > Automations > Create > Trigger: Webhook. Copy the webhook ID into the app config.

## Configuration Points

| Platform | Where to set HA URL / Webhook ID |
|----------|----------------------------------|
| Android | `android/.../MoveHomeViewModel.kt` — `SmartHomeConfig(...)` |
| iOS | `ios/MoveHome/App/MoveHomeViewModel.swift` — `SmartHomeConfig(...)` |
| Garmin | `garmin/resources/resources.xml` — `HA_BASE_URL`, `WEBHOOK_ID` |

## Key Constraints

- Garmin Monkey C has no MQTT library and no KMP support — HTTP only, manual port
- iOS CoreMotion reports in g-force, not m/s² — always convert before the recognizer
- Android SensorManager nanosecond timestamps — divide by 1,000,000 for ms
- Garmin sensor data arrives in milli-g batches — iterate the array, scale each sample
- The iOS XCFramework must be rebuilt (`assembleXCFramework`) after any change to `:shared`

## Adding a New Gesture

1. Add the value to `shared/.../model/GestureType.kt`
2. Add detection logic in `shared/.../gesture/GestureRecognizer.kt`
3. Mirror the same logic in `garmin/source/gesture/GestureRecognizer.mc`
4. Update Home Assistant automations to handle the new gesture label
