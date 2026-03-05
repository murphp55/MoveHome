# MoveHome

Gesture-based smart home control using the built-in accelerometer on your phone or Garmin watch. Shake, tap, or tilt your device to trigger Home Assistant automations.

## How it works

MoveHome samples accelerometer data continuously. When a gesture is detected it sends an HTTP POST to a Home Assistant webhook, which can trigger any automation — lights, locks, scenes, etc.

Supported gestures: **shake**, **tap**, **double tap**, **tilt up/down/left/right/forward/backward**

---

## Home Assistant Setup (all platforms)

1. In Home Assistant go to **Settings > Automations & Scenes > Create Automation**
2. Add a trigger of type **Webhook** and note the generated webhook ID
3. Add whatever action you want (toggle a light, run a script, etc.)
4. Enter your Home Assistant local IP and that webhook ID into the app (see platform sections below)

The app sends this payload on every gesture:
```json
{ "gesture": "shake", "device": "android_phone" }
```
You can use `{{ trigger.json.gesture }}` in HA templates to branch on gesture type.

---

## Android

### Setup
1. Open the project in Android Studio
2. Edit `haBaseUrl`, `webhookId`, and `deviceId` in [MoveHomeViewModel.kt](android/src/main/kotlin/com/movehome/android/MoveHomeViewModel.kt)
3. Run on a physical device (emulator has no real accelerometer)

### Usage
- Tap **Start** on screen to begin listening, **Stop** to end
- Press the **Volume Down** button as a hands-free toggle
- The last detected gesture is shown in the center of the screen
- Gestures are sent to Home Assistant automatically as they are detected

---

## iOS

### Setup
1. Build the shared framework first:
   ```
   ./gradlew :shared:assembleXCFramework
   ```
   This produces `shared/build/XCFrameworks/release/Shared.xcframework`
2. Open `ios/MoveHome.xcodeproj` in Xcode, drag `Shared.xcframework` into the project under Frameworks
3. Edit `haBaseUrl`, `webhookId`, and `deviceId` in [MoveHomeViewModel.swift](ios/MoveHome/App/MoveHomeViewModel.swift)
4. Run on a physical iPhone (simulator has no real accelerometer)

### Usage
- Tap **Start** to begin listening, **Stop** to end
- The last detected gesture is displayed on screen
- Gestures are sent to Home Assistant automatically

### Back Tap (hands-free trigger)
iOS Back Tap lets you toggle gesture capture without touching the screen:

1. Go to **Settings > Accessibility > Touch > Back Tap**
2. Choose **Double Tap** or **Triple Tap**
3. Assign a **Shortcut** that opens the URL `movehome://trigger`
4. Add `movehome` as a URL scheme in your app's `Info.plist` under `CFBundleURLSchemes`

The app handles the URL scheme and toggles capture automatically.

---

## Garmin (Connect IQ)

### Supported Devices
Fenix 6/7 series, Vivoactive 4, Venu 2, Forerunner 945/255. Additional devices can be added to [manifest.xml](garmin/manifest.xml).

### Setup
1. Install the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and VS Code extension
2. Edit [garmin/resources/resources.xml](garmin/resources/resources.xml):
   ```xml
   <string id="HA_BASE_URL">http://192.168.1.100:8123</string>
   <string id="WEBHOOK_ID">movehome_garmin</string>
   <string id="DEVICE_ID">garmin_watch</string>
   ```
3. Build and sideload via the Connect IQ simulator or deploy to your device

### Usage
- Press any watch button to toggle gesture capture on/off
- The watch face shows **Listening...** when active and the last gesture detected
- Gesture events are sent over WiFi to Home Assistant (the watch must be on the same network or have a data connection)

---

## Architecture

```
MoveHome/
├── shared/          # Kotlin Multiplatform — gesture logic shared by Android + iOS
│   └── src/commonMain/kotlin/com/movehome/shared/
│       ├── model/           # AccelerometerSample, GestureType
│       ├── sensor/          # SensorDataProcessor (low-pass filter)
│       ├── gesture/         # GestureRecognizer (sliding window classifier)
│       └── smarthome/       # SmartHomeClient (Ktor HTTP → HA webhook)
├── android/         # Android app (Jetpack Compose)
├── ios/             # iOS app (SwiftUI + Shared.xcframework)
└── garmin/          # Garmin Connect IQ app (Monkey C)
```

The gesture recognition algorithm (sliding window, variance/peak/tilt detection) is implemented once in Kotlin and shared between Android and iOS via KMP. The Garmin implementation is a hand-matched port of the same algorithm in Monkey C, using identical thresholds.

---

## Gesture Reference

| Gesture | Motion |
|---------|--------|
| `shake` | Rapid back-and-forth motion |
| `tap` | Single sharp impact |
| `double_tap` | Two quick impacts within 400 ms |
| `tilt_up` | Face pointing upward (Z+ sustained) |
| `tilt_down` | Face pointing downward (Z−) |
| `tilt_left` | Rolled left (X−) |
| `tilt_right` | Rolled right (X+) |
| `tilt_forward` | Pitched forward (Y+) |
| `tilt_backward` | Pitched backward (Y−) |

Gesture labels in HA templates match the `label` field exactly (e.g. `double_tap`).
