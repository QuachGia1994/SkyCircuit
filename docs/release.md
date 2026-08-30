# Release and artifacts

## Build authority

SkyCircuit is often developed from Windows, so GitHub Actions is the platform build authority for macOS/Xcode and clean Android packaging.

A green workflow proves that source compiled and the expected artifact was packaged. It does not by itself prove runtime behavior on a physical phone.

## Artifact matrix

| Workflow | Artifact | Purpose | Direct device install? |
| --- | --- | --- | --- |
| Android APK | `SkyCircuit-Beta-Installable-APK` | Beta device testing | Yes; debug-signed |
| Android APK | `SkyCircuit-Beta-Unsigned-APK` | Archive/re-sign pipeline | No; unsigned |
| Native Android V2 | `SkyCircuit-Native-Android-V2-Unsigned-APK` | Native sidecar validation | No; unsigned |
| Native iOS V2 | `SkyCircuit-Native-iOS-V2-Beta-Unsigned-IPA` | Full-access native iOS beta package | Requires sideload/signing workflow |
| Native iOS V2 | `SkyCircuit-Native-iOS-V2-Beta-Simulator` | Native Simulator testing | Simulator only |
| iOS Simulator | `SkyCircuit-iOS-Simulator` | Capacitor fallback validation | Simulator only |

## Beta behavior

Beta builds intentionally unlock premium preview functionality so skins/modes can be tested without production store accounts.

This behavior must remain explicit:

- Android/web beta build: `SKYCIRCUIT_BETA=1`.
- Native iOS beta build: `-DSKYCIRCUIT_BETA`.

Production entitlement code must not depend on beta flags being enabled.

## Android installation

For direct Android testing, download `SkyCircuit-Beta-Installable-APK` from the latest successful **Android APK** workflow.

Do not attempt to install `SkyCircuit-Beta-Unsigned-APK` directly. Android requires APK signatures.

If Android reports an existing-signature conflict, uninstall the previous beta build before installing a package signed with a different debug key.

## Native iOS beta

The native iOS workflow compiles with code signing disabled and creates an unsigned IPA-shaped package for testing/signing workflows.

This is not an App Store-ready archive. Production distribution still requires:

- Apple Developer team configuration.
- Production bundle/signing/provisioning setup.
- StoreKit product configuration.
- TestFlight validation.
- App Store metadata/privacy review.

## Pre-release checklist

Engineering:

- [ ] `npm test` passes.
- [ ] `npm run build` passes.
- [ ] `git diff --check` passes.
- [ ] Android APK workflow is green.
- [ ] Native iOS V2 workflow is green.
- [ ] Any affected native sidecar workflow is green.
- [ ] No generated artifacts/DerivedData are committed.
- [ ] No beta entitlement bypass is enabled in production configuration.

Gameplay:

- [ ] Source component can fan out to every actually connected rocket.
- [ ] Unconnected rockets do not launch.
- [ ] Ignition traversal remains readable at `0.14 s/stage`.
- [ ] Rocket flight/firework payoff completes before board consumption.
- [ ] Pause blocks gameplay input and clearly darkens the playfield.
- [ ] Cascade/combo behavior is stable.

UX:

- [ ] Startup shows one branded loading experience, not duplicate logos.
- [ ] Tutorial can complete and replay.
- [ ] Plus screen is usable on compact phones without overflow.
- [ ] EN / VI / JA / KO / zh-Hans / FR are complete for changed surfaces.
- [ ] Music, SFX, and haptics settings persist.
- [ ] Phone-speaker audio is audible at normal device volume.

Release/legal:

- [ ] App icon variants final.
- [ ] App Store / Play Store screenshots prepared.
- [ ] EN/VI store metadata prepared.
- [ ] Privacy policy and Terms published.
- [ ] GDPR/CCPA/privacy-manifest review complete.
- [ ] Third-party media provenance still matches `CREDITS.md`.
- [ ] Repository/source licensing decision made before encouraging external redistribution.

## Verification vocabulary

Use precise status language in reports:

- **Local verified** — tests/static build passed on the development host.
- **CI verified** — relevant GitHub Actions platform build passed.
- **Packaged** — expected APK/IPA/Simulator artifact exists.
- **Runtime verified** — a defined device/simulator test matrix actually executed the app and passed acceptance checks.

At the current repository checkpoint, `runtime_verified: false` remains the conservative automation status. Manual owner testing has occurred, but no automated device-farm/runtime matrix is recorded as a release gate yet.

## Release notes

Use `CHANGELOG.md` for implementation history. For a public release, extract only user-visible changes and known limitations rather than publishing internal debugging history verbatim.
