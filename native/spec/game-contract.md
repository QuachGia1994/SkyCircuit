# Native V2 shared contract

## Product state
- Game phases: `playing`, `paused`, `gameOver`.
- Modes: Classic, Zen, Blitz.
- Daily Run tracks current streak, run progress, score, and mini rank.
- Plus entitlement gates premium skins/modes; native stores are the source of truth.

## Interaction
- A tile rotation reports a quality value in `0...1` based on how many conduit edges become valid after rotation.
- Haptics map quality to lower intensity and higher sharpness as the placement approaches optimal; launch/combo events use a distinct strong success pattern.
- Audio tempo follows combo/ignition speed and is generated at runtime.

## System surfaces
- iOS Live Activity / Android Live Update only runs while a user-started Daily Run is actively in progress.
- Persistent Daily Run streak and mini leaderboard belong in WidgetKit/Glance widgets, not a permanently pinned live activity.

## Render budget
- 120 Hz target frame budget: 8.3 ms.
- Renderer must degrade gracefully to 60 Hz when the display or device cannot sustain 120 Hz.
- No external texture/audio packs. Vector/procedural rendering is preferred; native app payload target is under 25 MB.

## Migration rule
Native V2 is additive until gameplay parity, crash-free instrumentation, native CI, and store entitlement flows are verified. Do not delete the Capacitor implementation during this experiment.
