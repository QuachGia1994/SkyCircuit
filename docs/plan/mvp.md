# SkyCircuit MVP

## Goal
Recreate the core rotate-and-connect fireworks puzzle feeling as an original mobile game without copying PopCap branding, code, art, audio, or level content.

## Included
- 8x8 circuit board with left-side sparks and right-side rockets.
- Tap-to-rotate tiles, branching connections, multi-rocket launches, burned-tile collapse, and refill.
- Timed level loop, score, combo bonus, high score, pause, and restart.
- Procedural visuals and audio with no third-party game assets.
- Android APK build workflow and unsigned iOS simulator build workflow.

## Acceptance
- `node --test` passes the board behavior tests.
- `npm run build` produces the static `dist/` web payload without a bundler.
- Android CI generates a debug APK after Capacitor creates the Android project.
- iOS CI compiles the generated Capacitor project for the iOS Simulator with code signing disabled.

## Constraint
A device-installable iOS IPA requires Apple signing credentials and provisioning. The unsigned simulator artifact is not an IPA substitute and must not be reported as one.
