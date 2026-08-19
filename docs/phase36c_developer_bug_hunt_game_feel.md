# Phase 36C — Developer Bug Hunt Feedback & Juice

## Goal

Make the Developer Bug Hunt Room feel responsive and game-like without changing progression, scoring, XP, reputation, skill-tree behavior, scenario content, or backend logic.

## Scope

Developer role only. This slice intentionally does not roll the feedback pattern into Data Cleanup Race or Blueprint Safety Puzzle.

## Changes

| ID | Change | Status |
|---|---|---|
| JUICE-01 | Correct production-blocker taps build a correctness-aware combo. | Implemented |
| JUICE-02 | Wrong target taps reset the combo immediately. | Implemented |
| JUICE-03 | Correct taps briefly pop the target card. | Implemented |
| JUICE-04 | Wrong taps shake the target card and the game scene. | Implemented |
| JUICE-05 | Correct/wrong taps emit distinct impact particle bursts. | Implemented |
| JUICE-06 | Correct taps reuse `notification_ping`; wrong taps reuse `comedy_bonk`. | Implemented |
| JUICE-07 | Combo x2+ is surfaced inside the Flame arena. | Implemented |
| JUICE-08 | Reduced-motion mode disables pop, shake, and impact-particle motion. | Implemented |
| JUICE-09 | Target feedback now uses the existing correctness-specific `feedback` copy. | Implemented |
| JUICE-10 | Existing XP and score impact remain unchanged. | Covered by regression test |

## Architecture decision

`BaseMiniGame` now exposes neutral presentation hooks for scene offset, target scale/offset, and target-tap feedback. Their defaults are no-op, so existing role mini-games retain their current presentation. `BugHuntRoomGame` is the only game opting into Phase 36C effects.

This keeps the Developer vertical slice isolated while avoiding duplicated hit-testing/layout logic.

## Validation target

1. `flutter analyze --no-fatal-warnings --no-fatal-infos` passes.
2. Full Flutter tests pass.
3. Phase 36C tests confirm combo correctness and unchanged score/XP behavior.
4. Web release build passes.
5. Android debug APK build passes.
6. Shareable artifacts are uploaded before merge.

## Intentionally deferred

- Production sprite animation and final character art.
- Collision/pathfinding/navigation mesh.
- Keyboard/controller/virtual-stick movement.
- Production-quality office/campus environment art.
- Applying this feedback system to the other seven role paths.
- External 5–10 person playtest, which should happen after the Developer vertical slice is visually approved.
