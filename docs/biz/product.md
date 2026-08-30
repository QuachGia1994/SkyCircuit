# SkyCircuit product direction

> Beta checkpoint: 2026-08-30

## Identity

SkyCircuit is an original mobile circuit puzzle built around one satisfying loop: rotate conduits, complete a powered component, watch ignition travel through the circuit, then launch the rockets actually connected to that component.

The product aims for short, readable sessions with a high-quality mechanical/fireworks payoff rather than a large rule set.

## Audience

Primary audience:

- Casual mobile puzzle players.
- Players who prefer short portrait sessions.
- Users attracted to tactile rotate/connect mechanics and strong audiovisual payoff.
- Players who can understand the first move from a three-step tutorial without prior franchise knowledge.

## Core value proposition

The puzzle action is intentionally simple. Depth comes from:

- Reading larger circuit topology quickly.
- Planning rotations that create branches and multi-rocket launches.
- Managing time pressure in Classic/Blitz.
- Pursuing cascades and combo value.
- Choosing a relaxed Zen session when timer pressure is not desired.
- Meta progression and recurring challenges after retention is validated.

## Free product direction

Free launch should establish the core retention signal before monetization expands.

Expected Free baseline:

- Classic mode.
- Classic Circuit visual theme.
- Tutorial/help.
- Local best score/streak.
- Daily Run entry point.
- Sensible rewarded/interstitial ad strategy only after D1/D7 measurement is available.

Current beta builds intentionally expose more content than the future Free baseline so testers can validate all gameplay and visual paths.

## Plus direction

SkyCircuit Plus is intended as a weekly/monthly subscription, not a default lifetime unlock.

Proposed recurring value:

- No ads.
- Exclusive themes/pulses.
- Early access to modes/levels.
- Periodic Plus rewards.
- Expanded recurring challenge/event content.

Current beta artifacts use explicit full-access flags so testers can exercise premium prototypes without production store configuration.

## Current Plus roadmap shown in-app

- Plus skins — prototype ready.
- Zen + Blitz — prototype ready.
- Daily Challenge — next.
- Weekly Events — later.
- Leaderboards — later.
- Seasonal themes — later.

The iOS Plus screen mirrors the Android mobile hierarchy and roadmap while retaining StoreKit 2 as the production entitlement boundary.

## Retention roadmap

Before adding large systems, measure:

- Tutorial completion.
- D1 / D7 retention.
- Average session duration.
- Runs per day.
- Classic vs Zen vs Blitz usage.
- Launch count and multi-launch frequency.
- Combo/cascade distribution.
- Daily Run participation.
- Theme/Plus-preview engagement.

These signals should decide which roadmap item receives investment next.

## Monetization principles

- Do not compromise the core loop to force purchases.
- Do not build a complex economy before retention data exists.
- Ads should be context-appropriate and measurable.
- Premium entitlement logic must be store-backed in production.
- Beta full access must never become an accidental production bypass.
- Purchase, settings, retention, and gameplay analytics should exist only when the data has an explicit product decision attached.

## Product constraints

- Portrait mobile-first.
- Lightweight renderer and payload.
- Procedural/vector-first visuals.
- One documented CC0 BGM dependency; gameplay SFX remain lightweight/procedural.
- Cross-platform gameplay meaning must remain aligned even when UI technology differs.
- Do not copy legacy game branding, source, artwork, audio, or level data.
