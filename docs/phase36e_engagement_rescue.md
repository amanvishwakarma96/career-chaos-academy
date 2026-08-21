# Phase 36E — Engagement Rescue / Gameplay Loop Overhaul

## Trigger
A real 30–40 minute play session felt boring. Follow-up feedback identified the specific cause: the app repeatedly asks MCQ/FAQ-style questions or timer variants, does not process work automatically, rarely creates a genuinely new task, and repeats the same interaction pattern.

This is now the highest-priority product blocker. Visual polish is secondary until the core loop creates action, tension, surprise, and a reason to continue.

## Source audit — why the app feels like a quiz wrapper

| ID | Problem | Evidence / impact | Status |
| --- | --- | --- | --- |
| ENG-01 | Generic mini-game types mostly resolve to radio buttons, checkboxes, dropdowns, or move-up/down lists. | Different labels still produce almost the same player behavior. | OPEN globally; Developer slice replaced |
| ENG-02 | Developer Chapter 1 launched Bug Hunt after dialogue, but Bug Hunt was still a target-selection game. | The visual wrapper changed, not the core interaction. | REPLACED in this slice |
| ENG-03 | Game state barely changed unless the player tapped an answer. | World feels passive and waits for the player rather than behaving like a live workplace. | FIXED in Developer incident slice |
| ENG-04 | No automatic work processing. | Tap immediately equals answer; no sense of tools running, tests executing, deployment progressing, or systems reacting. | FIXED in Developer incident slice |
| ENG-05 | No evolving task chain inside a run. | Player sees one prompt rather than receiving new work as the situation develops. | FIXED in Developer incident slice |
| ENG-06 | Shortcuts and wrong actions usually become text feedback instead of changing the simulation. | Weak stakes and low tension. | FIXED in Developer incident slice |
| ENG-07 | Dialogue is mostly passive Next/Next/Next interaction until the post-dialogue gate. | Low action frequency; player watches more than plays. | OPEN — next slice |
| ENG-08 | Post-chapter Result screen is report-heavy. | Breaks pacing and delays return to play. | OPEN — next slice |
| ENG-09 | Developer hub still has limited activity variety and no short-session objective. | Weak “one more task / one more run” motivation. | OPEN |
| ENG-10 | Production art placeholders remain unresolved. | Important, but secondary to retention. | DEFERRED until engagement improves |

## Slice B — Live Production Incident

Developer Bug Hunt is converted from target selection into a workflow simulation while keeping the same route and reward contract.

### Player loop

1. **Inspect logs** — processing runs automatically and reveals evidence.
2. **Reproduce bug** — validates the failure path.
3. **Patch state** — applies the technical fix.
4. **Run tests** — executes regression verification.
5. **Open PR** — creates review evidence and rollback notes.
6. **Deploy fix** — stabilizes production when the workflow is ready.

### World behavior

- Production health declines while the player waits.
- Monitoring/client/QA/Senior events appear automatically in a live feed.
- Each tool has real processing time instead of instant answer validation.
- Finishing one task automatically generates the next task.
- Actions can be attempted out of order.
- Risky shortcuts increase chaos and damage production health.
- Unsafe deploy attempts trigger an automatic rollback and can be recovered from.
- A verified deploy automatically restores production health to 100%.
- Completed workflow steps persist during the run; there is no “clear answers and resubmit” loop.
- Existing success/failure XP and score-impact values remain unchanged.

## What this intentionally stops doing

- No “select the correct production blockers” MCQ pattern for Developer Chapter 1.
- No fixed five-card answer set.
- No shuffled-question solution pretending to be gameplay variety.
- No instant tap → correctness result as the primary loop.
- No requirement that every mistake ends the run; recovery is part of the gameplay.

## Next engagement slices

1. **Interactive dialogue pacing** — insert actions/interruptions inside scenes; target meaningful input every 20–40 seconds.
2. **Result pacing rescue** — show punchy consequence/reward first; move coaching/safety/debrief into expandable details.
3. **Developer task variety** — add distinct simulation families: incident triage, release pipeline, code-review conflict, support escalation, performance debugging, and outage recovery.
4. **Session director** — automatically choose the next task based on recent mechanic/history so the player does not receive the same game repeatedly.
5. **Short-session objective** — 5-minute shift, incident quota, streak, rotating modifier, or changing daily objective.
6. Roll the validated loop system to other roles only after Developer playtests stop feeling repetitive.

## Acceptance criteria for this slice

- Developer Chapter 1 no longer plays as an MCQ/FAQ/target-selection round.
- The simulation changes even when the player does nothing.
- Tool actions visibly process over time.
- The next task appears automatically after progress.
- Out-of-order actions cause mechanical consequences, not only explanatory text.
- Unsafe play can be recovered through correct workflow.
- A successful verified deploy stabilizes the incident automatically.
- Existing XP and score-impact contracts remain unchanged.
- Analyzer/tests/web/APK CI stays green.
- Follow-up human playtest question: **“Does this feel like doing a job under pressure instead of answering a course quiz?”**
