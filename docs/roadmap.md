# Roadmap

SkyCircuit has reached a feature-complete beta checkpoint. The next work should validate retention and release readiness rather than continuously adding mechanics without evidence.

## Current checkpoint

Implemented and exercised in beta:

- Core 8×8 rotate/connect loop.
- Branching connected-component launches.
- Staged ignition + rocket/firework cinematic.
- Classic, Zen, Blitz, and Daily Run entry flow.
- Four visual themes.
- Tutorial, settings, pause/restart.
- EN / VI / JA / KO / zh-Hans / FR.
- Shared arcade BGM + procedural gameplay SFX.
- Plus preview hierarchy and beta full-access mode.
- Android installable/unsigned beta artifacts.
- Native iOS unsigned beta/Simulator artifacts.
- Cross-platform regression tests and CI compilation.

## Product roadmap

### Phase 1 — Free launch validation

Goal: validate whether the core loop retains players before expanding the economy.

- Ship a stable Free build.
- Instrument D1/D7 retention, session length, level attempts, launch/combo frequency, tutorial completion, and mode usage.
- Keep ads restrained: rewarded + context-appropriate interstitial only after retention is measurable.
- Tune difficulty progression so gameplay does not become a short repeating loop.

### Phase 2 — Meta progression

- Coins/economy with explicit sources/sinks.
- Theme/skin/pulse unlock progression.
- Daily streak rewards.
- Achievements.
- Data-driven level sets with meaningful progression.

### Phase 3 — SkyCircuit Plus

Plus is intended as weekly/monthly subscription, not a default lifetime purchase.

Proposed benefits:

- No ads.
- Exclusive skins/pulses.
- Early access to new modes/levels.
- Periodic Plus rewards.
- Expanded Daily/weekly content.

Production requirements:

- StoreKit 2 purchase, restore, and `Transaction.updates` on iOS.
- Equivalent Play Billing entitlement flow on Android.
- Entitlement persistence/recovery tests.
- Localized paywall/store copy.
- Clear Terms/Privacy links.

### Phase 4 — Shared content

Current roadmap labels shown inside Plus:

- Plus skins — prototype ready.
- Zen + Blitz — prototype ready.
- Daily Challenge — next.
- Weekly Events — later.
- Leaderboards — later.
- Seasonal themes — later.

Daily Challenge should be deterministic/seeded so all players receive the same puzzle objective for a given day.

### Phase 5 — Platform services

- Game Center authentication.
- Achievements.
- Leaderboards with offline submission queue/retry.
- Android equivalent service integration where product scope requires it.
- Live Activity/Dynamic Island only when an active Daily Run has meaningful progress to display.
- Widget mini leaderboard/streak surfaces.

### Phase 6 — Reliability and release operations

- Crash reporting with useful breadcrumbs and non-fatal error capture.
- Privacy manifest and ATT/privacy review.
- Analytics abstraction tied to retention/monetization decisions.
- Thermal/Low Power degradation policy.
- Automated accessibility/localization gates.
- Performance benchmarks for 60/120 Hz targets.
- App payload <25 MB where practical.
- TestFlight/App Store and Play Store release checklists.

## What not to do next

Until retention or performance data justifies it:

- Do not add a second iOS renderer.
- Do not migrate to Unity/Flutter/KMP.
- Do not add complex physics.
- Do not add large external art/audio packs.
- Do not build a large backend solely because the roadmap mentions leaderboards/events.
- Do not add monetization mechanics that are not connected to a measured product decision.

## Release gate

A roadmap phase is complete only when the relevant source tests and platform CI are green. Compilation/packaging is not equivalent to real-device runtime validation; release candidates still require manual or automated device testing.
