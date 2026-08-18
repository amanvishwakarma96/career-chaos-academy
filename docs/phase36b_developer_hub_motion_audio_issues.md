# Phase 36B — Developer Hub Motion & Audio Issue List

This document tracks the game-feel problems discovered while converting the Developer role from a static menu-like experience into a persistent Flame hub. It separates issues fixed in this slice from limitations that should remain visible for the next visual pass.

| ID | Issue | Status in this slice | Notes / remaining limitation |
|---|---|---|---|
| HUB-01 | Developer avatar is a static marker and does not feel like a controllable game character. | Fixed | The avatar now walks toward a tapped destination before content opens. Movement is presentation-only and does not change progression. |
| HUB-02 | No idle motion makes the hub feel frozen when the player is not interacting. | Fixed | Added lightweight idle bob/pulse motion. Reduced-motion mode disables it. |
| HUB-03 | Tapping a destination opens content immediately, so the hub does not communicate physical travel. | Fixed | Location selection now enters a walking state, highlights the destination, updates status text, and opens content after arrival. |
| HUB-04 | Hub had no ambient audio. | Fixed | Reuses the existing `AudioService` and registered `bgm_office_light` loop. Hub music stops while story/game content is active and resumes when the player returns. Browser autoplay rules may still require the first pointer interaction before audio begins. |
| HUB-05 | Reduced-motion preference was not propagated into the Flame hub. | Fixed | The hub listens to `AnimationService.reducedMotion`. Reduced motion removes idle/walk animation and enters a destination immediately. Overlay transition duration also becomes zero. |
| HUB-06 | Hub status UI only said “tap a location” and did not communicate walking/mission state. | Fixed | Added live status messages such as walking, entering, and mission-active states. |
| CI-01 | `MiniGameModel.fromJson` referenced `_readOptionalString` that was not defined in `MiniGameModel`. | Fixed | Added the optional string parser to `MiniGameModel`. |
| CI-02 | Three Flame mini-games declared a static `definition` that conflicts with the inherited instance `definition` field on `BaseMiniGame`. | Fixed | Renamed static definitions to `gameDefinition` and updated `FlameMiniGameFactory`. |
| CI-03 | `InterviewModeScreen` instantiated `VoiceSettingsScreen` without importing its file. | Fixed | Added the direct screen import. The screen already existed. |
| CI-04 | `ScenarioScreen` used the `MiniGameTypeX.label` extension without importing `mini_game_model.dart`. | Fixed | Added the direct model import. |
| CI-05 | `ParallaxSceneBackground` referenced `GameAssetType` without importing `asset_registry.dart`. | Fixed | Added the direct registry import. The enum already existed. |
| CI-06 | `SkillTreeScreen` used an informational `EmptyState` while `EmptyState` required an action label/callback. | Fixed | `EmptyState` now supports either an actionable state or an informational state, while asserting that action label/callback are supplied together. |
| HUB-07 | Avatar is still procedurally drawn rather than using production character art/sprite animation. | Open | Keep this visible for the next art pass. Do not block the current interaction architecture on final assets. |
| HUB-08 | Walking uses direct interpolation and has no collision/pathfinding/navigation mesh. | Open | Acceptable for the two-location vertical slice. Add path constraints only when the hub layout is approved. |
| HUB-09 | No keyboard/controller/virtual-stick movement yet. | Open | Current interaction is tap-to-walk, suitable for mobile/web validation. Broader controls should follow only if the hub proves fun. |
| HUB-10 | Background remains a stylized procedural tech map rather than a polished office/campus environment. | Open | Requires the next visual-art/environment pass after this interaction slice is approved. |
| CI-07 | Repository-wide deprecated Flutter API usage may still exist outside files touched by this slice. | Open | Let CI identify the remaining concrete analyzer findings; fix them separately rather than mass-editing unrelated screens blindly. |

## Acceptance target for this slice

1. Developer role opens the existing persistent Flame hub.
2. Tapping Production Office or Bug Hunt Lab visibly moves the avatar before opening content when reduced motion is off.
3. Reduced motion removes hub travel/idle movement and avoids animated overlay transition.
4. Existing office background music is used as hub ambience and does not overlap story/mission audio.
5. Returning from mission content restores the same hub state instead of rebuilding a menu flow.
6. Existing scenario, scoring, XP, reputation, skill-tree, and backend behavior remains unchanged.
7. GitHub Actions must pass analyze/tests and produce shareable web/APK artifacts before merge.
