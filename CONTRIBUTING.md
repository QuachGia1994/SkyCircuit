# Contributing to SkyCircuit

SkyCircuit is currently a tightly scoped mobile-game project. Contributions should preserve gameplay clarity, cross-platform parity, small payload size, and deterministic behavior rather than adding framework complexity.

## Before changing code

Read:

- `README.md`
- `docs/architecture.md`
- `docs/development.md`
- `docs/design.md`
- `native/spec/game-contract.md` for cross-platform gameplay expectations

For substantial work, define the problem and acceptance criteria before editing. Prefer root fixes over symptom patches.

## Engineering expectations

- Keep gameplay rules separate from rendering/UI.
- Add a regression test for bug fixes when the behavior can be expressed deterministically.
- Preserve Android/iOS semantics when changing launch, burn, combo, mode, Plus, localization, or audio behavior.
- Prefer value types for models/state snapshots.
- On native iOS, keep mutable game/UI state on `@MainActor` and use async/await for asynchronous work.
- Do not add a second renderer or major framework without measured need.
- Avoid `try!`, silent failures, dead code, and premature abstractions.
- Keep public/user-facing strings localized.

## Visual contributions

SkyCircuit uses a procedural/vector-first visual system. New UI should match the cosmic Liquid Glass / industrial circuit language described in `docs/design.md`.

Do not introduce third-party artwork, music, fonts, or other media without explicit licensing/provenance documentation. The current external BGM exception is documented in `CREDITS.md`.

## Required local gates

```bash
npm test
npm run build
npm run docs:check
git diff --check
```

Platform-specific changes must also pass their GitHub Actions workflow before being considered complete.

## Commit style

Use focused imperative commit subjects, for example:

```text
Fix branching launch resolution
Mirror Android Plus roadmap on iOS
Improve phone speaker audio mix
```

Avoid commits that mix unrelated gameplay, documentation, and infrastructure changes unless they are one inseparable root fix.

## Generated files

Do not commit:

- `dist/`
- generated Capacitor `android/` or `ios/` folders
- APK/IPA artifacts
- DerivedData/build output
- `.DS_Store`
- transient logs

## Localization

Supported launch languages are EN / VI / JA / KO / zh-Hans / FR. Any new required user-facing key should be added across all six languages in the same change.

## Beta vs production entitlements

Beta full access exists so testers can exercise Plus content. Do not turn that test path into a production entitlement bypass.

- iOS production authority: StoreKit 2.
- Android native production authority: Play Billing.

## Pull requests

A useful pull request description should include:

- What problem is fixed or feature is added.
- Behavior before/after.
- Tests added or changed.
- Relevant platform CI result.
- Screenshots/video for visual changes when available.
- Known limitations or follow-up work.

## Licensing note

The repository currently does not declare a project-wide source license. Contributions should not assume a redistribution/relicensing grant beyond what the repository owner explicitly provides.
