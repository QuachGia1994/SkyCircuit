# Native shared game contract

This contract defines behavior that must remain equivalent across the shared Capacitor path and native platform implementations. Rendering technology may differ; gameplay meaning must not.

## Product state

Game phases:

- `playing`
- `paused`
- `gameOver`

Modes:

- Classic
- Zen
- Blitz

Daily Run tracks streak/progress/score/rank state where the platform surface supports it.

SkyCircuit Plus gates premium skins/modes in production. Beta builds may explicitly unlock premium preview content through compile/build flags.

## Circuit connectivity

- The board is an 8×8 conduit grid.
- Neighbor traversal requires mutually compatible conduit edges.
- A source-connected component succeeds when it reaches at least one real rocket endpoint.
- A successful component burns as a whole.
- Every rocket endpoint genuinely reachable inside that successful component may launch.
- One source may fan out to multiple connected rockets.
- Rockets not connected through valid conduit edges must not launch.
- Curved routes are valid regardless of source/rocket row alignment.
- Multi-source components calculate burn distance from the nearest source.

This component rule is authoritative and supersedes older one-source/one-rocket or same-row pairing experiments.

## Launch cinematic

Current parity timing constants:

- Burn stage duration: `0.14 s`.
- Rocket flight duration: approximately `1.55 s`.
- Firework burst begins after the rocket has visibly left the board, around the latter portion of the flight.

Sequence:

1. Interaction completes a valid component.
2. Ignition travels through conduit topology stage by stage.
3. Connected rockets launch.
4. Firework visual + crack/boom/sparkle payoff occurs.
5. Only after the cinematic finishes may the board consume/collapse/refill.
6. Cascades may then resolve.

## Interaction feedback

Tile rotations may report a placement/connection quality value in `0...1`.

Haptics should map interaction quality to a useful intensity/sharpness response and use a distinct success pattern for launch/combo moments. Haptics must remain optional in settings.

## Audio

Both current Android/web and native iOS beta paths use the same CC0 gameplay BGM source: `assets/audio/duru-arcade-vibe.mp3`.

- Baseline playback rate is approximately `1.08x`.
- Higher combo/ignition energy may raise playback rate up to approximately `1.16x`.
- Gameplay interaction, ignition, launch, and firework effects remain synthesized/lightweight.

Audio implementation APIs may differ by platform, but the user-facing semantic cues should remain equivalent.

## Pause behavior

Pause must:

- Block gameplay progression/input that would change the board.
- Clearly darken/suppress the playfield so the user understands the session is paused.
- Preserve resumable state.

Modal presentation during ignition should not create contradictory gameplay state.

## Tutorial and startup

- Tutorial has three conceptual steps: rotate, connect, ignite/launch.
- Help remains replayable after first run.
- Only one visible branded startup/loading experience should be presented.
- Platform-native launch screens may provide a brief neutral transition but must not duplicate the full branded splash.

## Plus parity

The mobile Plus product hierarchy should remain aligned:

1. Premium roadmap header.
2. Live skin preview.
3. 2×2 skin cards.
4. Stacked Classic/Zen/Blitz mode cards.
5. Stacked Plus benefits.
6. Wrapped roadmap chips.
7. Gold roadmap footer.
8. Beta full-access or production store state.

Roadmap labels:

- Plus skins — prototype ready.
- Zen + Blitz — prototype ready.
- Daily Challenge — next.
- Weekly Events — later.
- Leaderboards — later.
- Seasonal themes — later.

## Localization

Launch language set must remain equivalent across parity-sensitive platform surfaces:

- EN
- VI
- JA
- KO
- zh-Hans
- FR

Required user-facing sections must not silently fall back to hardcoded English when the selected language is supported.

## Entitlements

- Beta full access must be explicit and test-only.
- Production iOS entitlement source of truth: StoreKit 2.
- Production native Android entitlement source of truth: Play Billing.
- Persisted beta state must not bypass production entitlement checks.

## System surfaces

- iOS Live Activity / Android live/ongoing surface should only represent meaningful active Daily Run progress.
- Persistent streak and mini-rank are better suited to WidgetKit/Glance than a permanently pinned live activity.

## Render and power budget

- Target 120 Hz where hardware/performance permit: ~8.3 ms frame budget.
- Degrade gracefully to 60 Hz.
- Pause/large modal screens should suspend unnecessary heavy rendering.
- Effects should be reducible under thermal/Low Power pressure when that policy is fully implemented.
- Avoid premature object pooling or renderer replacement without benchmark evidence.

## Media and payload

- Procedural/vector visuals are preferred.
- The documented CC0 BGM is an intentional external-media exception.
- Do not add large texture/audio packs without a measured reason and explicit licensing documentation.
- App payload target remains under 25 MB where practical.

## Verification rule

Cross-platform behavior changes require deterministic regression tests where feasible plus green affected CI workflows.

CI compilation/package success does not equal real-device runtime verification. Release status must distinguish local, CI, packaged, and runtime-verified states.
