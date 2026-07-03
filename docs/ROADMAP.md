# Product and Engineering Roadmap

## Current milestone: Phase 36 vertical-slice approval

Goal: validate the new game-quality visual direction before scaling it across all roles.

Acceptance focus:

- Developer Chapter 1 feels cinematic and game-like.
- Bug Hunt Room is responsive and understandable.
- Visual effects remain readable and performant.
- Performance/Balanced/Cinematic quality modes behave correctly.
- Reduced-motion mode remains usable.
- Progress, scoring, analytics, and scenario logic are unchanged.

## Milestone 1: Visual QA and stabilization

- Run Flutter analyze and full test suite.
- Test Android, iOS, and web.
- Profile frame times, memory, asset load time, and battery impact.
- Test low-end Android hardware.
- Fix layout overflow and touch-target issues.
- Add golden/screenshot tests for critical Flutter overlays.
- Add Flame component tests where deterministic.

## Milestone 2: Art and motion system

- Approve a single art direction and asset-production guide.
- Create reusable character rigs or sprite standards.
- Define motion tokens, easing, duration, and feedback rules.
- Replace placeholder visual/audio assets.
- Add optimized atlases, particles, VFX, and environment layers.
- Establish asset budgets per scene and device quality tier.

## Milestone 3: Visual rollout

- Apply the approved system to remaining Developer chapters.
- Upgrade Data Cleanup Race and Blueprint Safety Puzzle.
- Roll out role-by-role with regression checks.
- Preserve feature flags for controlled release.

## Milestone 4: Platform productionization

- Migrate JSON runtime data to a managed database.
- Add Redis-backed sessions and distributed rate limiting.
- Add object/CDN storage for downloadable scenario packs and large assets.
- Introduce queues for reports, certificates, moderation, and AI jobs.
- Implement user data export, deletion, and anonymization.
- Complete encrypted backup and restore drills.

## Milestone 5: Provider integrations

- Production AI provider with reviewed prompts, budgets, and safety evaluation.
- TTS/STT provider with consent, retention, and fallback controls.
- Real payment/subscription provider with server-side receipt validation.
- Enterprise identity and organization provisioning.
- Production crash reporting and observability.

## Milestone 6: Beta and launch

- Closed learner beta.
- College/company pilot.
- Content accuracy and professional safety review.
- Accessibility audit.
- Penetration test.
- Store/legal/privacy readiness.
- Launch metrics and incident-response plan.
