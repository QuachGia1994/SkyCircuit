# Changelog

## [Unreleased]

### Added
- Initial SkyCircuit mobile puzzle prototype with rotatable circuit tiles, source-to-rocket connectivity, multi-rocket launches, collapse/refill, score, levels, timer, pause, restart, procedural gameplay SFX, vibration where supported, and local high score.
- Three-step first-run tutorial with replayable help.
- Classic, Zen, and Blitz modes plus four selectable visual skins.
- SkyCircuit Plus preview with benefits and product roadmap; purchase wiring remains intentionally absent.
- Original SkyCircuit app-icon source and Capacitor native icon generation in Android/iOS workflows.
- Static build pipeline and Capacitor configuration for Android and iOS packaging.
- Behavior-level tests for board rotation, connectivity, component isolation, staged ignition, multi-source ignition, and collapse/refill.
- Experimental Native V2 sidecars without replacing the Capacitor build: iOS SwiftUI + Canvas/TimelineView + CoreHaptics + AVAudioEngine + ActivityKit + StoreKit 2, and Android Jetpack Compose + SurfaceView Canvas + rich VibrationEffect + promoted Daily Run notification + Glance + Play Billing.
- Native iOS asset catalog with a real SkyCircuit AppIcon and branded startup splash, plus an unsigned full-access beta build channel that unlocks Plus themes and modes without production StoreKit configuration.
- Shared Native V2 contract for Daily Run streak/rank surfaces, Plus entitlement boundaries, 120 Hz render target under 8.3 ms, and an under-25 MB procedural/vector asset budget.
- Experimental Native V2 CI workflows for Xcode 27 and Android API 36/AGP 9.3.
- Shared CC0 gameplay BGM `duru-arcade-vibe` from the DURU CC0 BGM repository; Android/web and native iOS bundle the same source track while keeping ignition/launch/firework SFX procedural.

### Changed
- Completed circuits now ignite progressively through topology-ordered burn stages before rockets launch instead of lighting the whole path at once.
- The ignition head now travels through each conduit curve and splits across junction branches instead of jumping between tile centers.
- Rebuilt the gameplay art direction around the approved premium concept: cosmic skyline, luminous brand/HUD, heavy beveled board chassis, industrial tile plates, metallic curved conduits with copper couplers, mechanical spark generators, glossy vertical rockets, and premium control surfaces.
- Plus/tutorial previews now use theme-aware rocket and ignition artwork instead of flat triangle glyphs, and page atmosphere follows the active skin.
- Reduced mobile canvas cost by capping DPR at 2, removing per-particle blur, guarding HUD DOM writes, and adding iOS glass-filter and resize handling.
- Cascade launches now expose an explicit combo chain in the HUD and scoring flow.
- Launch resolution now treats each source-connected circuit as one component: every truly connected rocket endpoint can launch together from a single branching source, the full successful component burns, and multi-source distance merging keeps ignition propagation topology-correct.
- Android CI now emits both a true release unsigned beta APK for archive/re-sign and a debug-signed installable beta APK for direct device testing; CI verifies the installable APK signature with `apksigner`. Native Android V2 remains pinned to Compose 1.11/BOM 2026.04.01 on stable Android API 36.
- Android startup now uses only a brief native transition before the shared branded loading splash; Plus skin previews own proper clipping boxes on WebView, and heavy Canvas/background repaint work is suspended while modal UI is open to reduce scroll jank.
- Replaced the slow procedural background pad with the faster CC0 `duru-arcade-vibe` arcade loop, played at 1.08× baseline and up to 1.16× under combo/ignition pressure on both Android/web and native iOS.
- Native iOS Plus now mirrors the Android mobile hierarchy: live skin preview, 2×2 skin grid, stacked Classic/Zen/Blitz cards, stacked benefit cards, wrapped roadmap chips, gold roadmap footer, and beta/StoreKit purchase status with six-language localization.
