# SkyCircuit native implementations

`native/` contains additive native platform implementations used to validate platform-specific production features while preserving the shared gameplay contract.

## iOS

`native/ios/` is the current native iOS beta path.

- Swift 6 strict concurrency.
- SwiftUI-first application shell.
- `@MainActor @Observable final class GameEngine` for mutable game/UI state.
- SwiftUI `Canvas` + `TimelineView` lightweight renderer.
- StoreKit 2 entitlement boundary.
- CoreHaptics/Taptic feedback.
- Shared CC0 BGM + AVFoundation/procedural gameplay SFX.
- ActivityKit Daily Run Live Activity prototype.
- WidgetKit streak/mini-rank surface.
- EN / VI / JA / KO / zh-Hans / FR localization.
- Full-access unsigned beta build via `SKYCIRCUIT_BETA`.

The iOS implementation intentionally does **not** maintain a parallel SpriteKit renderer. SpriteKit should only be introduced if measured gameplay/performance requirements justify it.

## Android

`native/android/` is the additive native Android V2 sidecar.

- Jetpack Compose shell.
- Native Canvas render view.
- Native haptic/audio helpers.
- Play Billing entitlement boundary.
- Daily Run notification/system-surface prototype.
- Glance widget prototype.
- Stable Android API 36 build path.

The direct-install Android beta used most frequently for device testing currently remains the Capacitor/shared-JS implementation built by `.github/workflows/android.yml`.

## Shared contract

`spec/game-contract.md` defines behavior that must remain aligned across implementations, including:

- Connected-component launch semantics.
- Burn/rocket timing expectations.
- Mode and Plus entitlement meaning.
- Daily Run system-surface intent.
- 60/120 Hz performance goals.
- Payload/media constraints.

## Migration rule

Native implementations are additive until a release decision explicitly replaces another path. Do not delete a working fallback merely because a native sidecar compiles.

Any migration should require:

- Gameplay parity tests.
- Relevant platform CI green.
- Real-device runtime acceptance.
- Store entitlement verification.
- Accessibility/localization verification.
- Crash/performance evidence appropriate for release.
