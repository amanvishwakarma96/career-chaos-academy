# Phase 36E — Engagement Rescue

## Trigger
A real 30–40 minute play session felt boring. This is a product-level blocker: visual polish alone is not enough if the core loop does not create curiosity, tension, choice, and replay value.

## Source audit — boredom causes

| ID | Problem | Evidence / impact | Status |
| --- | --- | --- | --- |
| ENG-01 | Dialogue is mostly passive Next/Next/Next interaction until the post-dialogue gate. | Low action frequency; player watches more than plays. | OPEN — next slice |
| ENG-02 | Developer Bug Hunt uses a fixed five-card incident set. | Once learned, replay has almost no surprise. | FIXED in this slice |
| ENG-03 | Wrong Bug Hunt calls have feedback/juice but weak gameplay pressure. | Mistakes feel cosmetic instead of dangerous. | FIXED in this slice |
| ENG-04 | Fast correct play has combo feedback but little mechanical advantage. | Skillful play does not change the run enough. | FIXED in this slice |
| ENG-05 | Post-chapter Result screen is a long report containing consequence, lesson, mentor, AI coach, safety, takeaway, simulation context, debrief, rank and score cards. | Breaks pacing after the dramatic moment and delays return to gameplay. | OPEN — next slice |
| ENG-06 | Failure still unlocks story choices. | Good for accessibility, but weakens perceived stakes unless the run creates stronger immediate consequences. | PARTIAL — retain accessibility, strengthen moment-to-moment pressure |
| ENG-07 | Developer hub currently exposes only Production Office and Bug Hunt Lab. | Limited activity variety in a longer session. | OPEN |
| ENG-08 | Most education/support information is surfaced automatically instead of on demand. | App can feel like a course/report wrapped in game visuals. | OPEN |
| ENG-09 | No explicit short-session objective such as a 5-minute run, streak target, incident quota or changing daily objective. | Player lacks a strong "one more run" reason. | OPEN |
| ENG-10 | Visual art placeholders remain unresolved. | Important, but secondary to gameplay retention. | DEFERRED until engagement loop improves |

## Slice A — Bug Hunt replayability and pressure

1. Build each Bug Hunt run from a larger incident pool.
2. Keep exactly three real production blockers and two decoys per run so existing success rules remain compatible.
3. Shuffle both incident selection and card order.
4. Wrong calls temporarily accelerate the incident clock.
5. Fast correct combos temporarily slow the incident clock.
6. Add a live incident-pressure HUD and critical visual state.
7. Preserve existing XP and score-impact contracts.
8. Preserve reduced-motion behavior.

## Next slice — pacing rescue

After Slice A validates, prioritize:

1. Add meaningful interaction inside dialogue scenes instead of waiting until the end.
2. Reduce uninterrupted dialogue stretches; target a player action every 20–40 seconds.
3. Replace the Developer Result wall with a punchy outcome/reward summary first and optional expandable coaching details.
4. Add a short-session objective and rotating challenge modifier to create a "one more run" loop.
5. Expand hub activity variety only after the first two activities are genuinely replayable.

## Acceptance criteria

- Replaying Bug Hunt can produce a visibly different incident set/order.
- A wrong selection changes actual time pressure, not only animation/SFX.
- A fast correct streak gives a small mechanical recovery.
- XP and score outputs remain unchanged for success/failure.
- Analyzer/tests/web/APK CI stays green.
- A follow-up human play session should specifically answer: "Did I want to retry immediately?" and "Was I making decisions frequently enough?"
