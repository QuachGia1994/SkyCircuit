# Changelog

## [Unreleased]

### Added
- Initial SkyCircuit mobile puzzle prototype with rotatable circuit tiles, source-to-rocket connectivity, multi-rocket launches, collapse/refill, score, levels, timer, pause, restart, procedural audio, vibration where supported, and local high score.
- Three-step first-run tutorial with replayable help.
- Classic, Zen, and Blitz modes plus four selectable visual skins.
- SkyCircuit Plus preview with benefits and product roadmap; purchase wiring remains intentionally absent.
- Original SkyCircuit app-icon source and Capacitor native icon generation in Android/iOS workflows.
- Static build pipeline and Capacitor configuration for Android and iOS packaging.
- Behavior-level tests for board rotation, connectivity, component isolation, staged ignition, multi-source ignition, and collapse/refill.

### Changed
- Completed circuits now ignite progressively through topology-ordered burn stages before rockets launch instead of lighting the whole path at once.
- Cascade launches now expose an explicit combo chain in the HUD and scoring flow.
