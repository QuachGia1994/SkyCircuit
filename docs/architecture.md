# Architecture

## Overview

SkyCircuit currently maintains one shared gameplay implementation for the Capacitor path plus native platform sidecars used to validate platform-specific production upgrades.

The project deliberately keeps gameplay rules separate from presentation. Rendering may differ by platform, but launch resolution, burn timing, combo semantics, mode intent, localization coverage, Plus entitlement boundaries, and artifact expectations must remain behaviorally aligned.

## Repository map

```text
assets/                  Shared visual/audio sources
scripts/                 Static build helpers
src/                     Shared JS gameplay/data/UI logic
styles.css               Shared responsive visual system
index.html               Capacitor/web shell
test/                    Behavior and parity regression tests
native/
  ios/                   SwiftUI native implementation
  android/               Jetpack Compose native implementation
  spec/                  Cross-platform game contract
docs/                    Product, engineering, design, and release docs
.github/workflows/       CI build authority
```

## Shared gameplay model

The circuit is an 8×8 grid of tiles whose connections are represented as directional bitmasks. Valid traversal requires mutual edge compatibility between neighboring tiles.

A launch is resolved by connected component, not by row:

1. Find components reachable from one or more left-side sources.
2. Determine whether each component reaches at least one actual rocket endpoint on the right.
3. If it does, the entire successful component participates in the burn animation.
4. Every rocket endpoint genuinely reachable in that component may launch.
5. Burn distance is calculated from the nearest participating source so multi-source components ignite naturally.
6. After the cinematic completes, burned tiles are consumed, survivors collapse, the board refills, and cascades may resolve again.

This prevents both historical failure modes: a valid curved route being rejected because it ended on another row, and one source incorrectly launching rockets that were not connected.

## iOS native architecture

The current native iOS implementation is SwiftUI-first.

- `GameRootView` is the application shell and HUD.
- `GameEngine` is an `@MainActor @Observable final class` that owns mutable gameplay/UI state.
- Gameplay models use structs/enums/value semantics.
- The lightweight board renderer uses SwiftUI `Canvas` and `TimelineView` rather than SpriteKit.
- StoreKit 2 is isolated behind `StoreManager`.
- Audio uses the shared CC0 BGM through AVFoundation plus procedural gameplay SFX.
- Haptics use CoreHaptics/Taptic feedback where appropriate.
- Daily Run system surfaces use ActivityKit/WidgetKit prototypes.

The renderer target is 120 Hz where hardware and thermal state permit, with graceful fallback to 60 Hz. The game does not maintain a second SpriteKit renderer in parallel.

## Android architecture

### Capacitor beta path

The currently installable Android beta uses:

- Capacitor 8 as the native container.
- Canvas 2D for the board and cinematic effects.
- Responsive HTML/CSS for HUD, tutorial, settings, and Plus.
- Web Audio for interaction/SFX and the shared CC0 BGM.
- Native Android splash/icon generation through `@capacitor/assets` and Capacitor plugins.

This path is the most exercised Android device-test channel at the current checkpoint.

### Native Android V2

The additive native sidecar uses Jetpack Compose plus a native Canvas renderer and contains platform prototypes for haptics, billing, Daily Run notification surfaces, and Glance widgets.

It remains isolated under `native/android/` so the stable beta path can continue to ship while native parity evolves.

## State and concurrency

Rules for native iOS code:

- UI/game mutable state is main-actor isolated.
- Async operations use async/await.
- No `try!`.
- Errors should use concrete error types where recovery or reporting matters.
- Value types are preferred for model/state snapshots.
- Classes are reserved for lifecycle ownership, platform service wrappers, and observable engines/managers.
- Avoid abstraction layers until more than one real implementation requires them.

## Entitlements and beta behavior

Premium UI and gameplay must distinguish test access from production entitlement:

- Beta CI compiles explicit full-access flags so testers can exercise Plus skins/modes without a store transaction.
- Production source must not silently restore or bypass premium content without a valid entitlement.
- iOS production entitlement authority is StoreKit 2.
- Android native production entitlement authority is Play Billing.

Beta unlocks are compile-time/test-environment behavior, not product pricing decisions.

## Localization

Supported launch languages:

- English (`en`)
- Vietnamese (`vi`)
- Japanese (`ja`)
- Korean (`ko`)
- Simplified Chinese (`zh-Hans`)
- French (`fr`)

Regression tests check cross-platform language parity and required Plus roadmap keys. User-facing strings should not be added directly to gameplay views when a localization key is appropriate.

## Audio and media

Visuals are generated procedurally/vector-first. The single intentional external media dependency is:

- `assets/audio/duru-arcade-vibe.mp3` — CC0 background music.

Interaction tones, ignition, launch, crack/boom/sparkle firework effects, and most visual effects remain generated by code. See `CREDITS.md` for provenance.

## CI as verification authority

Development is frequently performed from Windows, so GitHub Actions is the source of truth for platform compilation:

- Android installable and unsigned APK packaging.
- Capacitor iOS Simulator compilation.
- Native iOS Xcode 27 Simulator build.
- Native iOS unsigned device build and IPA packaging.
- Native Android V2 release compilation.

A source phase is not considered platform-compile complete until the relevant workflow is green.

CI compilation is not the same as real-device runtime verification; see `release.md`.
