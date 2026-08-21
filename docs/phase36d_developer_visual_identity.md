# Phase 36D — Developer Visual Identity Pass

## Goal

Make the Developer hub read as a game space rather than a dark menu with cards, while keeping all progression, scoring, XP, reputation, skill-tree, scenario, and backend behavior unchanged.

## Asset audit

The current art directories are not production-ready:

- `assets/game/characters/developer_neutral.png` — 68-byte placeholder.
- `assets/game/characters/developer_focused.png` — 68-byte placeholder.
- `assets/game/characters/developer_worried.png` — 68-byte placeholder.
- `assets/game/backgrounds/office_morning.png` — 68-byte placeholder.
- `assets/game/backgrounds/production_war_room.png` — 68-byte placeholder.

Because these files do not contain usable production art, Phase 36D does not pretend that loading them improves visual quality. The hub remains asset-ready, but this slice upgrades the actual rendered scene procedurally until real art is supplied.

## Issues and status

| ID | Issue | Status | Notes |
|---|---|---|---|
| VIS-01 | Hub reads like floating menu cards instead of a physical workplace. | Fixed in this slice | Locations are now represented by office/lab structures with embedded interaction plates. |
| VIS-02 | Background is a generic gradient/grid without depth. | Fixed in this slice | Added skyline depth, perspective floor plane, lighting, and environmental props. |
| VIS-03 | Developer avatar still looks like a stick figure. | Improved | Replaced with a more character-like silhouette: clothing, skin/head, hair, laptop, legs/arms, shadow, and movement pose. |
| VIS-04 | Production Office has no visual identity. | Fixed in this slice | Added glass frontage, desk row, monitors, and production signage. |
| VIS-05 | Bug Hunt Lab has no visual identity. | Fixed in this slice | Added incident-feed screen, scan line, magenta lab treatment, and server-rack context. |
| VIS-06 | Existing character PNGs are placeholders. | Open / asset blocker | Requires real production sprite/character art. |
| VIS-07 | Existing office/war-room PNGs are placeholders. | Open / asset blocker | Requires final environment art or approved generated/illustrated assets. |
| VIS-08 | Character has no real sprite-sheet animation. | Open | Procedural walk/idle remains until production sprite frames exist. |
| VIS-09 | Environment lacks authored parallax layers and foreground occlusion. | Open | Add after final visual direction is approved. |
| VIS-10 | No dedicated tablet/mobile visual QA screenshots yet. | Open until artifact review | Validate from CI web/APK artifacts before merge. |

## Acceptance target

1. Developer hub remains persistent and navigation behavior is unchanged.
2. Production Office and Bug Hunt Lab read as physical spaces, not just menu cards.
3. Developer avatar is visibly more character-like while preserving current tap-to-walk behavior.
4. Reduced-motion behavior remains intact.
5. No scoring, XP, reputation, skill-tree, scenario, or backend changes.
6. Analyzer/tests pass and web/APK shareable artifacts are generated before merge.

## Next after approval

If this direction is visually accepted, the next milestone should replace placeholder art with a coherent production asset pack and add authored sprite animation/parallax. If it is not accepted, revise the Developer vertical slice before rolling any visual system to other roles.
