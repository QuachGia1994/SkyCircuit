# SkyCircuit

[![Android APK](https://github.com/QuachGia1994/SkyCircuit/actions/workflows/android.yml/badge.svg)](https://github.com/QuachGia1994/SkyCircuit/actions/workflows/android.yml)
[![iOS Simulator](https://github.com/QuachGia1994/SkyCircuit/actions/workflows/ios.yml/badge.svg)](https://github.com/QuachGia1994/SkyCircuit/actions/workflows/ios.yml)
[![Native iOS V2](https://github.com/QuachGia1994/SkyCircuit/actions/workflows/native-ios-v2.yml/badge.svg)](https://github.com/QuachGia1994/SkyCircuit/actions/workflows/native-ios-v2.yml)
[![Native Android V2](https://github.com/QuachGia1994/SkyCircuit/actions/workflows/native-android-v2.yml/badge.svg)](https://github.com/QuachGia1994/SkyCircuit/actions/workflows/native-android-v2.yml)

SkyCircuit is an original mobile fireworks circuit puzzle. Rotate conduit tiles, complete powered components, watch ignition travel through the network, then launch every rocket that is genuinely connected to that source component.

The project is inspired by the broad rotate-and-connect puzzle pattern of early mobile/PC puzzle games, but does **not** use PopCap code, branding, art, audio, levels, or other proprietary content.

> **Project state:** feature-complete beta checkpoint. Gameplay, cross-platform visual parity, tutorial, localization, audio, Plus roadmap, Android installable beta packaging, and native iOS unsigned beta packaging are implemented. Store release, production analytics, signed App Store distribution, and formal device-farm validation remain future release work.

## What is implemented

- 8×8 circuit board with left-side spark sources and right-side rockets.
- Tap-to-rotate conduits with loops, junctions, branching paths, collapse, refill, and cascade combos.
- Connected-component launch semantics: one source may fan out to multiple rockets, but only rockets actually reachable through valid conduit edges launch.
- Staged ignition at `0.14 s/stage`, followed by rocket flight and procedural fireworks.
- Classic, Zen, Blitz, and Daily Run flows.
- Local best score, streak, mode/theme persistence, pause/restart, and first-run 3-step tutorial.
- Classic Circuit, Nova Gold, Nebula Violet, and Plasma Chrome themes.
- SkyCircuit Plus preview with benefits, mode/skin previews, roadmap, beta full-access mode, and StoreKit/Play Billing entitlement boundaries.
- EN / VI / JA / KO / zh-Hans / FR localization.
- Shared CC0 arcade background track plus procedural interaction, ignition, launch, and firework effects.
- iOS Live Activity/Widget and Android Daily Run system-surface prototypes.

## Platform implementations

| Platform | Current beta path | Renderer / UI | Test artifact |
| --- | --- | --- | --- |
| Android | Capacitor shell + shared JS gameplay | Canvas 2D + responsive HTML/CSS | `SkyCircuit-Beta-Installable-APK` |
| Android native V2 | Native sidecar | Jetpack Compose + native Canvas view | `SkyCircuit-Native-Android-V2-Unsigned-APK` |
| iOS | Native V2 | SwiftUI shell + Canvas + TimelineView | `SkyCircuit-Native-iOS-V2-Beta-Unsigned-IPA` |
| iOS fallback | Capacitor shell | Canvas 2D | `SkyCircuit-iOS-Simulator` |

The native implementations live under [`native/`](native/). Shared behavior expectations are documented in [`native/spec/game-contract.md`](native/spec/game-contract.md).

## Quick start

Requirements for the shared web/Capacitor implementation:

- Node.js 22+
- npm

```bash
npm install
npm test
npm run build
```

`npm run build` produces `dist/` using Node.js file APIs. The gameplay layer has no bundler or third-party game-engine dependency.

For Android packaging:

```bash
npx cap add android
npx capacitor-assets generate --android
npx cap sync android
```

Native iOS requires macOS/Xcode. This repository uses GitHub Actions as the verification authority when development is performed on Windows.

## CI artifacts

The repository intentionally publishes different artifact types for different purposes:

- **`SkyCircuit-Beta-Installable-APK`** — debug-signed Android beta for direct device installation.
- **`SkyCircuit-Beta-Unsigned-APK`** — release unsigned Android APK for archive/re-sign workflows; it is not directly installable.
- **`SkyCircuit-Native-iOS-V2-Beta-Unsigned-IPA`** — full-access unsigned native iOS beta package. Installing it on a physical device requires an appropriate sideload/signing workflow.
- **`SkyCircuit-Native-iOS-V2-Beta-Simulator`** — native iOS Simulator app.
- **`SkyCircuit-iOS-Simulator`** — Capacitor fallback Simulator app.

See [`docs/release.md`](docs/release.md) for the complete build and release matrix.

## Architecture principles

SkyCircuit follows a mobile-game production baseline:

- SwiftUI is the iOS shell; Canvas + TimelineView is the default lightweight renderer.
- `@Observable final class GameEngine` owns native iOS game/UI state on `@MainActor`.
- Value types model immutable gameplay state; reference semantics are used only where lifecycle/state ownership requires them.
- Async work uses async/await; no completion-handler architecture.
- Game rules are data-driven where practical and regression-tested before visual polish.
- Liquid Glass/material depth, icon/startup branding, localization, accessibility hooks, and CI are baseline requirements rather than post-launch polish.
- Visual assets are procedural/vector where practical. The one bundled external media asset is the CC0 background track documented in [`CREDITS.md`](CREDITS.md).

More detail: [`docs/architecture.md`](docs/architecture.md).

## Documentation

- [`docs/index.md`](docs/index.md) — documentation map.
- [`docs/architecture.md`](docs/architecture.md) — architecture and platform boundaries.
- [`docs/development.md`](docs/development.md) — local workflow, tests, CI, and contribution gates.
- [`docs/design.md`](docs/design.md) — visual language, gameplay feedback, accessibility, and localization rules.
- [`docs/roadmap.md`](docs/roadmap.md) — Free/Plus and post-beta roadmap.
- [`docs/release.md`](docs/release.md) — artifact matrix and release checklist.
- [`docs/biz/product.md`](docs/biz/product.md) — product direction and monetization intent.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — contribution expectations.
- [`CHANGELOG.md`](CHANGELOG.md) — implementation history.
- [`CREDITS.md`](CREDITS.md) — third-party media provenance.

## Verification status

Current source gates include Node behavior/regression tests, static web build checks, Android APK packaging/signature verification, iOS Simulator compilation, and native iOS unsigned device compilation/package generation.

`runtime_verified` remains **false as a repository/CI claim**: GitHub Actions proves compilation and packaging, but cannot itself prove real-device runtime behavior. Manual device testing by the project owner is valuable evidence, but formal automated device/simulator runtime validation is still a separate release gate.

## Licensing

No repository-wide source-code license has been declared yet. Do not assume permission to redistribute or relicense SkyCircuit source code. Third-party media has its own licensing terms documented in [`CREDITS.md`](CREDITS.md).
