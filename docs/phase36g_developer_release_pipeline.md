# Phase 36G — Developer Release Pipeline

## Goal

Add a second genuinely different Developer gameplay family so repeated Developer sessions alternate mechanics instead of replaying the same incident loop with different labels.

## Issue register

| ID | Requirement | Status |
| --- | --- | --- |
| PIPE-01 | Release Pipeline is a playable Developer task family | Fixed |
| PIPE-02 | First Developer session remains Live Incident for continuity | Fixed |
| PIPE-03 | Session Director alternates recent playable task families | Fixed |
| PIPE-04 | Pipeline stages advance automatically from real dependency state | Fixed |
| PIPE-05 | Runner capacity creates a parallelism/stability tradeoff | Fixed |
| PIPE-06 | Failed test/security-style work requires a real retry path | Fixed |
| PIPE-07 | Production is gated until build, tests, security and staging are green | Fixed |
| PIPE-08 | Unhealthy production canary can require rollback and re-approval | Fixed |
| PIPE-09 | Existing session modifiers change pipeline mechanics, not only copy | Fixed |
| PIPE-10 | Host can use simulation-specific progress/result/action language | Fixed |
| PIPE-11 | Developer reward/score contract remains unchanged | Fixed |
| PIPE-12 | Support Escalation and Performance Profiling stay hidden until implemented | Fixed |

## Gameplay model

Release Pipeline is not an answer-card quiz. The player operates a live CI/CD system:

1. Start the pipeline.
2. Source and Build run automatically when dependencies are ready.
3. Tests and Security can run in parallel if the player spends stability on a second runner.
4. Staging unlocks only after both verification gates are green.
5. Production waits for explicit player approval.
6. A failed job must be retried; a failed production canary must be rolled back before another approval.
7. Release health and chaos change while the pipeline is active.

## Modifier behavior

- **Traffic Spike** — first production canary can fail under load and require rollback.
- **Flaky Test Suite** — first valid test attempt fails and requires a real retry.
- **Client Escalation** — stakeholder pressure adds chaos while the release remains open.
- **Noisy Alert Storm** — non-blocking monitoring noise competes with real pipeline signals.
- **Hotfix Window** — jobs process faster but release health decays over time.

## Persistence and compatibility

- Uses the existing `FlameMiniGameResultModel` persistence path.
- Session metadata continues to live inside the existing `gameId` format.
- No progress schema migration.
- No backend change.
- No XP, score, reputation or skill-tree rule change.

## Validation

Required before Phase 36G is ready for review:

- analyzer error gate passes
- full Flutter test suite passes
- Phase 36F anti-repeat regression tests pass after family expansion
- Phase 36G pipeline/family-routing tests pass
- web release build passes
- Android debug APK passes
- both shareable artifacts upload

## Deferred after Phase 36G

- Support Escalation gameplay
- Performance Profiling gameplay
- broader dialogue/debrief pacing cleanup for older mini-games
- production-quality art/sprite/environment pass remains a separate visual milestone
