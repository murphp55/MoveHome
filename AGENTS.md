# MoveHome — Agent Notes

## One-liner
Cross-platform (Android/iOS/Garmin) accelerometer gesture recognizer that fires Home Assistant webhooks; shared logic in Kotlin Multiplatform, Garmin manually ported to Monkey C.

## Run it
```
# Android
./gradlew :android:assembleDebug

# iOS framework (then open Xcode)
./gradlew :shared:assembleXCFramework
# Output: shared/build/XCFrameworks/release/Shared.xcframework

# Garmin
./gradlew :garmin:build
```

## Where we are right now
- Last touched: 2026-03-08
- Working on: Dormant — no recent activity (3 commits, last was a Monkey C import fix).
- Known broken: Nothing known. README.md is currently modified locally (uncommitted).

*This section goes stale fast. Check `git log -5` and `git status` before trusting it.*

## Gotchas
- **Garmin algorithm is a manual Monkey C port** of `shared/.../gesture/GestureRecognizer.kt` — keep `garmin/source/gesture/GestureRecognizer.mc` in sync whenever thresholds or detection logic change.
- **iOS CoreMotion reports g-force**, not m/s². Multiply by 9.81 before feeding samples into the KMP recognizer.
- **Garmin sensor data arrives in milli-g batches** — iterate the array and scale each sample by `9.81 / 1000.0`.
- **Android SensorManager timestamps are nanoseconds** — divide by 1,000,000 for ms.
- **iOS does NOT use KMP `SmartHomeClient`** — `HomeAssistantClient.swift` uses URLSession directly. Changes to the shared HTTP client won't affect iOS.
- **XCFramework must be rebuilt** (`assembleXCFramework`) after any `:shared` change before iOS picks it up.

## Non-obvious conventions
- Tuning constants (SHAKE_VARIANCE_THRESHOLD=3.0, TAP_PEAK_THRESHOLD=18.0, DOUBLE_TAP_WINDOW_MS=400, TILT_FRACTION=0.65, COOLDOWN_MS=500) are duplicated in `GestureRecognizer.kt` and `GestureRecognizer.mc` — update both.
- Ktor HTTP engine is auto-resolved per target (okhttp on Android, darwin on iOS); no expect/actual wiring needed.
- HA config (URL, webhook ID, device ID) lives per-platform: Android/iOS in `MoveHomeViewModel`, Garmin in `garmin/resources/resources.xml`.
- Adding a gesture: edit `GestureType.kt` + `GestureRecognizer.kt` + `GestureRecognizer.mc` (three places).

See README.md for project description, tech stack, and feature list.
