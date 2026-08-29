# SkyCircuit Native V2

Experimental native sidecars for validating platform-specific upgrades without replacing the production Capacitor prototype.

- `ios/`: SwiftUI + SpriteKit, CoreHaptics, AVAudioEngine, ActivityKit, StoreKit 2.
- `android/`: Jetpack Compose + native Canvas view, rich `VibrationEffect`, Android Live Updates, Glance widget, Play Billing 9.
- `spec/`: shared behavior, performance, entitlement, and Daily Run contracts.

The existing web/Capacitor app remains the shipping fallback until both native sidecars prove gameplay parity and CI stability.
