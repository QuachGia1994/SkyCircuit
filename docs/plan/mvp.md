# SkyCircuit MVP

## Goal
Recreate the core rotate-and-connect fireworks puzzle feeling as an original mobile game without copying PopCap branding, code, art, audio, or level content.

## Included
- 8x8 circuit board with left-side sparks and right-side rockets.
- Tap-to-rotate tiles, branching connections, multi-rocket launches, burned-tile collapse, and refill.
- Topology-correct staged ignition that visibly travels from every connected source before rockets launch.
- Classic, Zen, and Blitz gameplay modes; score, cascade combo, high score, pause, and restart.
- First-run 3-step tutorial with replayable help.
- Classic Circuit, Nova Gold, Nebula Violet, and Plasma Chrome skins persisted locally.
- SkyCircuit Plus preview screen with benefits and roadmap; no fake purchase or entitlement backend.
- Original procedural visuals/audio plus an original app-icon source asset.
- Premium concept-aligned visual layer: cosmic skyline, luminous glass HUD, beveled metal chassis, industrial tile sockets, metallic curved conduits with copper couplers, mechanical spark emitters, glossy vertical rockets, and skin-aware Plus/tutorial previews.
- Mobile rendering guardrails: DPR capped at 2, no per-particle blur, guarded HUD writes, iOS backdrop-filter prefix, canvas resize handling, and roundRect fallback.
- Android APK and unsigned iOS Simulator workflows with Capacitor native icon generation.

## Acceptance
- `node --test` passes board behavior tests including staged burn topology and multi-source ignition.
- `npm run build` produces the static `dist/` web payload including icon assets without a bundler.
- Completed routes animate stage by stage before launch; the burn head visibly travels through conduit geometry and splits at junctions before rocket launch; cascade launches preserve combo progression.
- Tutorial, skins, Plus preview, Classic, Zen, and Blitz are reachable without a dead-end flow.
- Android CI generates native icons and a debug APK after Capacitor creates the Android project.
- iOS CI generates native icons and compiles the generated Capacitor project for the iOS Simulator with code signing disabled.

## Constraint
A device-installable iOS IPA requires Apple signing credentials and provisioning. The unsigned simulator artifact is not an IPA substitute and must not be reported as one.
