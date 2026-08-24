# Phase 36H — Developer Visual / Game-Feel Production Pass

## Goal

Make the approved Developer vertical slice feel more like an active game session and less like a Flutter training screen, without changing backend, progression, scoring, XP, reputation, or skill-tree contracts.

## Issue register

| ID | Problem | Status | Phase 36H treatment |
| --- | --- | --- | --- |
| VGF-01 | Live simulations sit inside a mostly static app-like card frame. | FIXED | Added `DeveloperGameFeelFrame` with reactive HUD framing, corner brackets, scan motion, vignette, glow and urgency state. |
| VGF-02 | Failure/success state is mostly communicated by text. | FIXED | Feedback language now drives danger/success accents and impact feedback. Danger events can shake the surface; success events glow green. |
| VGF-03 | Final seconds do not feel meaningfully different. | FIXED | Last 15 initialized seconds switch the frame to a critical-window state. Timer value `0` during initialization is explicitly not treated as critical. |
| VGF-04 | Developer mission host still looks like a generic screen around the Flame arena. | IMPROVED | Dynamic mission title in app bar, stronger mission badge, larger arena, reactive feedback panel and momentum treatment. |
| VGF-05 | Persistent Developer hub lacks enough foreground/ambient motion. | IMPROVED | Added reduced-motion-aware atmosphere overlay with light beams, particles, side depth and district/route state chips. |
| VGF-06 | Reduced-motion setting must disable decorative motion and shake. | FIXED | Both new visual layers stop looping motion and impact shake when reduced motion is enabled. |
| VGF-07 | Current Developer avatar remains procedural rather than authored character art. | OPEN | Requires a real production character/sprite pack. Do not treat the procedural avatar as final art. |
| VGF-08 | Existing Developer/office PNG assets are placeholder-size files rather than production art. | OPEN | Requires authored binary assets and integration. |
| VGF-09 | No real multi-frame authored idle/walk sprite animation exists yet. | OPEN | Requires sprite sheet/frame assets; current movement remains procedural. |
| VGF-10 | Mission result is still a blocking modal rather than an in-world debrief. | OPEN | Recommended next game-feel/pacing slice after visual QA. |
| VGF-11 | Hub has no authored foreground occlusion/parallax environment layers. | OPEN | Current overlay adds depth but is not a substitute for production environment art. |
| VGF-12 | Visual improvements need real-device review for readability/performance. | PENDING QA | Validate with web + Android artifacts and user playtest. |

## Implementation

### Developer simulation surface

- `flutter_app/lib/widgets/developer_game_feel_frame.dart`
- reacts to existing `feedbackMessage` and `remainingSeconds` notifiers
- presentation only; does not own gameplay state
- danger state: red accent + impact shake
- success state: green accent/glow
- neutral state: cyan system treatment
- critical window: final 15 initialized seconds
- moving scan layer, vignette and HUD corner brackets
- reduced-motion aware

### Persistent Developer district

- `flutter_app/lib/widgets/developer_hub_atmosphere_overlay.dart`
- moving light beams and ambient particles
- foreground edge depth
- district-online badge
- free-roam / route-locked state based on existing hub status
- reduced-motion aware

### Host integration

- `flutter_app/lib/screens/flame_game_host_screen.dart`
- both Developer live mechanics inherit the same game-feel frame
- persistent hub gets the atmosphere overlay
- host mission title follows the active game definition
- arena presentation is larger and less card-like
- feedback panel changes visual tone with live state

## Guardrails

- Developer role only.
- No backend changes.
- No scoring/XP/reputation/skill-tree behavior changes.
- No new gameplay family in this phase.
- No placeholder bitmap is promoted as production art.
- Reduced motion remains functional.

## Recommended next milestone

After artifact-based visual QA, Phase 36I should address **authored production character/environment assets + sprite animation** if those assets can be integrated reliably. If asset integration is still blocked, prioritize the **in-world debrief / pacing pass** instead of adding more quiz-like or menu-level content.
