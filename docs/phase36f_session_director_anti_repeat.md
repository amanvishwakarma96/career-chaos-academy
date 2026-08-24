# Phase 36F — Developer Session Director + Anti-Repetition

## Why this phase exists

Phase 36E removed the most obvious quiz loop from Developer Bug Hunt, but one improved incident is still not enough for a 30–40 minute session. The app needs a director that remembers recent play, changes pressure automatically, and prevents the same run shape from repeating back-to-back.

## Issues

| ID | Problem | Status |
| --- | --- | --- |
| DIR-01 | No gameplay director chooses a changing Developer run. | FIXED — `DeveloperSessionDirectorService` now creates the next playable session plan. |
| DIR-02 | The same incident variant can repeat immediately. | FIXED — the director excludes the two most recent modifiers when alternatives exist. |
| DIR-03 | Anti-repeat state disappears after restart. | FIXED — plan IDs are encoded in the existing persisted Flame mini-game history; no new progress schema is required. |
| DIR-04 | “Variety” previously changed copy/card order more than mechanics. | FIXED for the live incident — modifiers now change health decay, event frequency, processing speed, escalation chaos, noisy signals, or test retry behavior. |
| DIR-05 | A flaky test was previously impossible; testing was always one-and-done. | FIXED — Flaky Test Suite can require a legitimate second test run while keeping the player on the same workflow task. |
| DIR-06 | Client pressure did not autonomously affect the run. | FIXED — Client Escalation adds chaos on a schedule while the incident remains open. |
| DIR-07 | Future task families could be surfaced before they are actually playable. | FIXED — the director filters to `isPlayable`; unfinished families are catalogued but never selected. |
| DIR-08 | Developer still has only one truly distinct playable task family. | OPEN — Phase 36G should implement Release Pipeline as the second real mechanic. |
| DIR-09 | Support Escalation and Performance Profiling are catalogued but not playable. | OPEN — implement after Release Pipeline proves the director pattern. |
| DIR-10 | Dialogue/result pacing can still interrupt the gameplay loop. | OPEN — retain for the pacing milestone after the second task family. |

## Playable modifiers in this slice

1. **Traffic Spike** — lower starting health and faster health decay.
2. **Flaky Test Suite** — first valid regression run fails transiently and creates a real retry task.
3. **Client Escalation** — faster pressure plus automatic chaos escalation.
4. **Noisy Alert Storm** — event feed contains extra non-blocking monitoring noise.
5. **Hotfix Window** — actions process faster, but production decays more aggressively.

## Persistence strategy

No progress-schema bump is needed. A run uses this existing Flame history ID format:

`flame_bug_hunt_room|<task-family>|<modifier>`

`ProgressService.recordFlameMiniGameResult` already persists the `gameId`, so the director can reconstruct recent plans after an app restart. Old history entries such as `flame_bug_hunt_room` remain valid and are simply ignored for modifier anti-repeat.

## Scope guardrails

- Developer role only.
- No backend changes.
- No XP or score-impact changes.
- No reputation or skill-tree changes.
- Unimplemented task families must never be shown as playable.
- Variety must change game state/mechanics, not only labels.

## Acceptance criteria

- The next run does not repeat either of the two most recent modifiers when alternatives exist.
- Selection is deterministic when a seed is supplied for tests.
- Existing/legacy Flame history remains compatible.
- Each modifier produces a measurable mechanical difference.
- Flaky tests create a retry instead of a wrong-answer state.
- Analyzer, full tests, web build and Android artifact build stay green.

## Next milestone — Phase 36G

Build **Release Pipeline** as a second truly different Developer mechanic: moving build stages, parallel/blocked jobs, rollback choice, release-window pressure and deploy health. The session director should then alternate task families, not merely modifiers inside Live Incident.
