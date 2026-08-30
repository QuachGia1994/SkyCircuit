# SkyCircuit beta/MVP checkpoint

## Goal

Deliver an original rotate-and-connect fireworks puzzle with enough production baseline to test real mobile retention: readable core loop, strong audiovisual payoff, platform parity, tutorial, settings, localization, beta artifacts, and a clear Plus roadmap.

## Implemented scope

### Gameplay

- 8×8 circuit board with left-side spark sources and right-side rocket endpoints.
- Tap-to-rotate conduit tiles.
- Mutual-edge connectivity with loops, junctions, branches, collapse, refill, and cascades.
- Connected-component resolver: every actually reachable rocket in a successful source component may launch.
- Multi-source burn distance merging.
- Staged ignition at `0.14 s/stage`.
- Rocket flight followed by procedural fireworks before board consumption.
- Score, combo, best score, pause/restart, and level progression shell.
- Classic, Zen, Blitz, and Daily Run entry flows.

### UX and visual baseline

- Portrait mobile-first layout.
- Cosmic Liquid Glass / industrial circuit visual language.
- App icon and startup branding.
- Single branded custom loading splash rather than duplicate platform logos.
- First-run three-step tutorial plus replayable help.
- Pause blackout treatment.
- Classic Circuit, Nova Gold, Nebula Violet, and Plasma Chrome themes.
- Android/iOS Plus hierarchy parity with live preview, skins, modes, benefits, roadmap, and beta/store state.

### Audio and haptics

- Shared CC0 `duru-arcade-vibe.mp3` BGM on Android/web and native iOS.
- Slight dynamic playback-rate increase with combo/ignition energy.
- Procedural interaction, ignition, launch, crack/boom, and sparkle SFX.
- Sound/music/haptics settings persistence.
- Haptic feedback hooks on supported native surfaces.

### Localization

Launch languages:

- English
- Vietnamese
- Japanese
- Korean
- Simplified Chinese
- French

Regression tests check required cross-platform localization coverage for parity-sensitive surfaces.

### Plus and platform services

- Beta full-access path for testing premium skins/modes.
- StoreKit 2 production entitlement boundary on native iOS.
- Play Billing boundary in native Android V2.
- iOS Daily Run Live Activity/Widget prototypes.
- Android Daily Run system-surface/widget prototypes.

### Packaging and CI

- Android direct-install beta APK with CI signature verification.
- Android unsigned release APK.
- Capacitor iOS Simulator artifact.
- Native iOS Simulator artifact.
- Native iOS full-access unsigned IPA packaging.
- Native Android V2 unsigned release APK.

## Current acceptance state

- Shared behavior/regression tests: PASS at the beta checkpoint.
- Static web build: PASS.
- Android beta packaging/signature workflow: established and green on the latest feature checkpoint.
- Native iOS Xcode 27 compile + unsigned IPA packaging: established and green on the latest feature checkpoint.
- Android/iOS Plus roadmap parity: implemented and regression-tested.
- Manual device testing: performed iteratively by the project owner during beta development.
- Automated real-device runtime matrix: not yet established.

## Deliberately deferred

The following are not required to call the current beta/MVP checkpoint feature-complete:

- Production App Store/Play Store signing and submission.
- Production StoreKit/Play product configuration.
- Ads SDK integration and retention-driven ad tuning.
- Production analytics/crash reporting.
- Game Center/production leaderboard backend.
- Daily Challenge shared seeded service.
- Weekly events and seasonal content pipeline.
- Full privacy policy/Terms/store metadata publishing.
- Automated device-farm runtime/performance/accessibility matrix.

## Constraint and verification wording

An unsigned iOS beta package is useful for downstream sideload/signing workflows but is not an App Store-ready signed IPA.

`runtime_verified` remains false as an automated repository claim until a defined device/simulator runtime test matrix is recorded and passed. CI compilation/package success must not be described as device runtime verification.
