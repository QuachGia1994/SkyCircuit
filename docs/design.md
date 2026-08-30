# Design

## Product feel

SkyCircuit should feel like a polished fireworks machine rather than a flat puzzle grid. The interaction is simple—rotate conduits—but the payoff comes from readable mechanical depth, ignition travel, rocket launch, audio, haptics, and fireworks.

## Visual language

The default language is dark cosmic Liquid Glass with strong hierarchy:

- Deep navy/black space background.
- Cyan/gold energy accents.
- Material/glass HUD surfaces with clear borders and depth.
- Industrial tile sockets and metallic conduit pieces.
- Copper couplers and mechanical spark emitters.
- Glossy rocket endpoints.
- Glow only where it communicates energy, selection, or payoff.

Avoid:

- Flat gray cards with no hierarchy.
- Over-blurred UI that reduces readability.
- Excessive text density.
- Decorative motion that competes with the circuit.
- Platform layouts that diverge without a platform-specific reason.

## Gameplay feedback sequence

A successful circuit should communicate success in this order:

1. The final tile interaction confirms placement with sound/haptic feedback.
2. The connected component begins staged ignition.
3. Burn travels through the actual conduit topology and visibly splits at junctions.
4. Connected rockets launch after the burn reaches the endpoint.
5. Rockets travel away from the board before fireworks burst.
6. Firework crack/boom/sparkle audio reinforces the visual burst.
7. Score/combo feedback updates.
8. Burned cells are consumed and the board collapses/refills.

The burn step duration is currently `0.14 s/stage`. Rocket flight is intentionally slower than burn traversal so the player can read the payoff.

## Cross-platform parity

Android and iOS do not need pixel-identical implementation technology, but they should present equivalent product hierarchy and feedback.

Parity-sensitive surfaces:

- Main gameplay HUD.
- Pause blackout state.
- Tutorial 3-step flow.
- Startup branding/loading.
- Classic/Zen/Blitz mode identity.
- Daily Run entry point.
- Plus skin previews, benefits, roadmap, and beta access state.
- Shared BGM and equivalent gameplay SFX semantics.
- Supported language list.

Platform-native material behavior is allowed when it improves integration without changing the product meaning.

## Plus screen hierarchy

The mobile Plus page should preserve this order on both platforms:

1. Premium roadmap header + close control.
2. Live skin preview.
3. 2×2 skin grid.
4. Stacked mode cards: Classic, Zen, Blitz.
5. Stacked Plus benefit cards.
6. Wrapped roadmap chips.
7. Gold roadmap footer.
8. Beta full-access status or production StoreKit/Play Billing purchase surface.

Roadmap chips currently communicate:

- Plus skins — prototype ready.
- Zen + Blitz — prototype ready.
- Daily Challenge — next.
- Weekly Events — later.
- Leaderboards — later.
- Seasonal themes — later.

## Tutorial

The tutorial is three steps:

1. Rotate a tile.
2. Connect a source to a rocket.
3. Watch ignition and launch.

It should demonstrate mechanics visually rather than relying on long text. First-run tutorial may auto-open after startup; the help button must allow replay later.

## Startup

Only one branded startup/loading experience should be visible to the player.

Native launch screens may provide a brief dark transition required by the platform, but must not duplicate the full SkyCircuit logo animation. The custom startup overlay owns the visible wordmark, localized tagline, and loading rail.

## Audio

Background music should be audible on phone speakers and energetic enough for repeated puzzle sessions without becoming stressful. The current shared loop is `duru-arcade-vibe.mp3`, licensed CC0.

Gameplay SFX remain procedural/lightweight:

- Rotation/placement cue.
- Ignition progression.
- Rocket launch.
- Firework crack, boom, and high-frequency sparkle.

Music and SFX have independent settings.

## Haptics

Haptic feedback should reinforce interaction quality, launch, and combo moments. Intensity/sharpness may vary with placement quality. Haptics must be optional and should reduce under low-power/thermal constraints when implemented.

## Accessibility

Design requirements:

- Interactive controls need meaningful accessibility labels.
- Text-heavy screens must tolerate Dynamic Type without clipping critical content.
- Reduce Motion should disable or simplify nonessential parallax/shake when fully wired.
- High Contrast support should preserve route readability and control boundaries.
- Color must not be the only indicator of selected/locked state.
- Pause should clearly remove gameplay focus visually and behaviorally.

## Localization

All user-facing content must support EN / VI / JA / KO / zh-Hans / FR. Layouts must be tested for expansion, especially Vietnamese/French labels and compact iPhone widths.

## Asset policy

Prefer procedural/vector assets for visuals. The project intentionally includes one external CC0 BGM file; any future external asset must have documented provenance and license before merge.
