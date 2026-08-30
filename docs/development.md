# Development

## Baseline

SkyCircuit uses a simple rule: implement the smallest correct behavior, lock it with tests, then polish presentation. CI is the platform compiler authority when working from Windows.

## Shared web/Capacitor workflow

Requirements:

- Node.js 22+
- npm

Install and verify:

```bash
npm install
npm test
npm run build
npm run docs:check
```

The test suite includes board connectivity, branching launches, curved-path regressions, burn topology, collapse/refill, splash/UI regressions, localization parity, audio parity, and Plus roadmap parity.

The static build writes `dist/`. Do not commit `dist/`, native generated Capacitor projects, DerivedData, APK/IPA artifacts, `.DS_Store`, or other generated build output.

## Android beta workflow

Local packaging skeleton:

```bash
npm run build
npx cap add android
npx capacitor-assets generate --android
npx cap sync android
```

CI produces two Android artifacts:

- `SkyCircuit-Beta-Installable-APK`: debug-signed and verified with `apksigner`; use this for direct device testing.
- `SkyCircuit-Beta-Unsigned-APK`: unsigned release package for archive/re-sign workflows; do not expect it to install directly.

The Android CI beta build sets `SKYCIRCUIT_BETA=1`, which enables test-only full access to premium preview content.

## Native iOS workflow

Native iOS source is under `native/ios/` and is generated/buildable with XcodeGen in CI.

Key constraints:

- Swift 6 strict-concurrency code.
- SwiftUI-first shell.
- `@MainActor @Observable final class GameEngine` for mutable game/UI state.
- Canvas + TimelineView for the lightweight renderer.
- StoreKit 2 for production Plus entitlements.
- `SKYCIRCUIT_BETA` compile flag for full-access beta testing.

The Native iOS workflow builds both Simulator and unsigned device outputs with Xcode 27.

## Native Android V2 workflow

Native Android V2 is under `native/android/` and builds against stable Android API 36. It is additive and should not break the Capacitor Android beta path.

## Change discipline

For non-trivial changes:

1. Update the live Aki plan.
2. Add or update behavior/regression tests first where possible.
3. Implement the smallest root fix.
4. Run local tests, static build, and `npm run docs:check` when documentation changes.
5. Run `git diff --check`.
6. Commit with one clear purpose.
7. Push `main`.
8. Let affected CI workflows run.
9. If CI fails, fix the root cause and repeat.
10. Update docs/plan only after the final relevant workflows are green.

Do not close a phase based only on local syntax checks when platform compilation is required.

## Coding rules

- Prefer guard/early return.
- Avoid `try!` and silent error swallowing.
- Keep functions focused and generally around 30 lines or less unless splitting would make the code worse.
- Use descriptive names rather than comments that explain unclear code.
- Prefer structs/enums for model data.
- Introduce protocols only when multiple real implementations or test seams justify them.
- Keep rendering code separate from connectivity/launch rules.
- Avoid maintaining duplicate renderers unless a measured requirement justifies it.

## UI rules

- Mobile-first portrait layout.
- Compact-phone layouts must not truncate primary branding or wrap mode labels unintentionally.
- Modal screens must not leave expensive game rendering running unnecessarily in the background.
- Pause must visibly suppress gameplay focus.
- Tutorial, settings, Plus, and gameplay status must use localized strings.
- VoiceOver/Dynamic Type should remain viable for interactive controls and text-heavy screens.

## Localization gate

Launch languages are EN / VI / JA / KO / zh-Hans / FR.

When adding a user-facing key:

1. Add English source text.
2. Add all five other launch-language values.
3. Add a parity regression if the key is required for a complete feature section.
4. Verify `.strings` files compile under Xcode CI.

## Audio rules

The shared BGM file is CC0 and must remain documented in `CREDITS.md`. Do not add third-party audio or images without explicit provenance/license documentation.

Gameplay SFX should remain lightweight and synthesized where practical. Mix changes must be checked on phone speakers, not only desktop/headphones.

## Useful commands

```bash
npm test
npm run build
npm run docs:check
git diff --check
git status --short
gh run list --limit 10
```

Use the Actions page to retrieve generated APK/IPA artifacts. Never commit generated packages to source control.
