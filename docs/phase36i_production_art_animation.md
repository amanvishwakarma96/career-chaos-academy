# Phase 36I — Developer Production Art & Character Animation

## Goal

Replace the Developer vertical slice's placeholder presentation path with authored, bundled vector animation assets while preserving gameplay, progression, backend, and reduced-motion contracts.

This phase intentionally does not claim final illustrator/AAA art quality. It establishes a real authored asset pipeline that can be refined without reverting to 68-byte placeholder PNGs.

## Issue register

| ID | Issue | Status | Phase 36I result |
| --- | --- | --- | --- |
| ART-01 | Developer neutral/focused/worried PNG files are 68-byte placeholders | BYPASSED | Existing character keys remain for compatibility, but Developer dialogue presentation routes them to the authored Lottie rig. |
| ART-02 | Developer has no authored idle animation | FIXED | Added `developer_idle.json` with body/head/arm ambient animation. |
| ART-03 | Developer has no authored walk animation | FIXED | Added `developer_walk.json` with opposing arm/leg walk keyframes and body movement. |
| ART-04 | Developer pressure states have no authored emotional variation | FIXED | Added `developer_worried.json` and emotion-to-rig routing. |
| ART-05 | Persistent hub's primary Developer presence is procedural geometry | FIXED FOR PRIMARY PRESENTATION | Hub now surfaces the authored idle/walk rig in the operator layer. The tiny Flame figure remains only as a navigation marker. |
| ART-06 | Release Pipeline lacks authored environment art | FIXED | Added animated production-office Lottie environment blended into the simulation frame. |
| ART-07 | Live Production Incident lacks authored environment art | FIXED | Added animated server/incident-lab Lottie environment blended into the simulation frame. |
| ART-08 | Art motion ignores reduced-motion preference | FIXED | Character and environment Lottie playback stops when reduced motion is enabled. |
| ART-09 | No deterministic asset contract for Developer art | FIXED | Added tests for JSON structure, keyframes, registry/versioning, emotion routing, and environment selection. |
| ART-10 | Real-device visual QA of new art | OPEN UNTIL CI ARTIFACTS | Validate web and Android artifacts after the branch passes the full workflow. |
| ART-11 | Other roles still rely on placeholder character/background assets | OPEN | Do not copy the Developer solution role-by-role until the Developer playtest proves the art direction works. |
| ART-12 | Final illustrator refinement, facial detail, turnarounds, bespoke frame-by-frame animation | OPEN | Current authored vector rig is a production-capable pipeline, not final high-end illustration. |
| ART-13 | Blocking result/debrief modal still interrupts game flow | OPEN | Pacing/debrief overhaul belongs in a later gameplay/presentation phase. |

## Implemented asset pack

Asset pack: `developer_visuals_v36i`  
Version: `36.9.0`

Character animation keys:
- `anim_developer_idle`
- `anim_developer_walk`
- `anim_developer_worried`

Environment animation keys:
- `anim_developer_office_environment`
- `anim_developer_lab_environment`

## Compatibility

- Existing `char_developer_*` registry keys remain intact so old scenario data does not require migration.
- `AnimatedCharacterPortrait` detects Developer references and renders the authored Lottie rig instead of the placeholder bitmap.
- Non-Developer character rendering is unchanged.
- No score, XP, reputation, skill-tree, scenario, backend, or persistence schema changes.

## Validation gate

Phase 36I is not complete until the pull request passes:
1. Flutter analyzer error gate.
2. Full Flutter tests, including `phase36i_production_art_test.dart`.
3. Web release build.
4. Android debug APK build.
5. Web artifact upload.
6. Android artifact upload.

## Human playtest after merge

Run the Developer route for 30–40 minutes and specifically judge:
- Does the character now feel present rather than like a placeholder card?
- Is the idle/walk transition readable in the hub?
- Do Live Incident and Release Pipeline feel visually distinct before reading their labels?
- Do the environment layers add depth without reducing UI readability?
- Does reduced-motion mode remain calm and understandable?

Only after this playtest should production art expansion begin for other roles.
