# Project Phase History — Legacy Delivery Notes

> Archived implementation notes from Phases 0–36. The root `README.md` is the current setup and product overview.


This package contains:

- `flutter_app/` — Flutter mobile app source with JSON-driven scenarios, local fallback, mini-games, gamification, release prep, and Phase 13 consequence engine and Phase 14A cinematic narrative scenes.
- `backend_nodejs/` — Node.js API and web admin panel.
- `docs/` — validation reports and delivery notes.

## Phase 13 Added

Phase 13 adds gameplay depth:

- consequence flags
- cleanup missions
- role-wise reputation
- finale/mastery endings
- scenario prerequisites and blocked-by flags
- result debriefs
- role dashboard
- mini-game success/failure consequences
- Node.js v4 progress schema
- admin CMS fields for consequence-driven content


## Phase 14A Added

Phase 14A adds a cinematic narrative layer:

- scene-based scenario JSON
- dialogue lines with speaker and emotion
- background image support
- character portrait support
- typing text effect
- skip dialogue and auto-play controls
- dramatic choice screen after dialogue
- consequence message after choice
- Node.js/admin validation for cinematic scene fields

Old simple scenario JSON remains supported. If a chapter does not define `scenes`, the app uses the existing scenario flow.

## Run Backend

```bash
cd backend_nodejs
npm install
npm run check
npm run test:smoke
npm start
```

Admin panel:

```text
http://localhost:5085/admin/
```

Default development credentials:

```text
admin / ChangeMe@123
```

## Run Flutter

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=CAREER_CHAOS_API_BASE_URL=http://10.0.2.2:5085
```

For Flutter web:

```bash
flutter run -d chrome --dart-define=CAREER_CHAOS_API_BASE_URL=http://localhost:5085
```

## Important Runtime Note

Flutter/Dart were not available in the sandbox used to prepare this package, so Flutter runtime validation must be completed locally.

## Phase 14B Added

Phase 14B adds a scalable visual asset system:

- structured folders for backgrounds, characters, props, badges, Lottie, Rive, and audio
- `AssetRegistry` with stable asset keys and legacy path aliases
- remote URL readiness for future CDN-hosted assets
- reusable `GameAssetImage` with missing-image fallback
- chapter-level asset preloading for cinematic scenes
- loading state while scene assets prepare
- missing asset placeholder support
- asset naming convention documentation
- asset compression guidelines
- admin help text for asset keys in cinematic scene JSON

New content should reference asset keys such as:

```json
{
  "backgroundImage": "bg_office_morning",
  "characterImage": "char_developer_worried"
}
```

Direct `assets/...` paths and remote `https://...` URLs remain supported for backward compatibility and future CDN usage.

## Phase 15 — Character Emotion Engine

Phase 15 adds reusable cinematic characters with emotion-driven expression mapping.

Key files:

```text
flutter_app/assets/game/characters/characters.json
flutter_app/lib/models/character_model.dart
flutter_app/lib/core/character_registry.dart
flutter_app/lib/widgets/animated_character_portrait.dart
flutter_app/test/phase15_character_engine_test.dart
```

Dialogue scenes can now reference a character by ID:

```json
{
  "speaker": "Senior Dev",
  "characterId": "senior_dev_mentor",
  "emotion": "serious",
  "text": "Small fixes are where production disasters wear tiny shoes."
}
```

The app resolves the speaker through `CharacterRegistry`, selects the correct expression for the current emotion, and falls back safely if the expression or character is missing.

Node.js backend also exposes:

```text
GET /api/characters
```


## Phase 16 — Motion Design Layer

Phase 16 adds a centralized animation system for cinematic gameplay without changing core progression rules.

Added:

- `AnimationService` with reduced-motion accessibility support.
- Motion-aware route transitions.
- Cinematic scene fade/slide/zoom transitions.
- Reduced-motion aware dialogue typing.
- Reduced-motion aware character entrance, shake, and zoom effects.
- Background parallax with safe disablement.
- Animated choice button entry and press feedback.
- Lottie feedback animations for success, failure, and badge unlock.
- Motion settings entry from the home screen.
- Performance guidance for low-end Android testing.

Local validation:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter run
```

Backend validation:

```bash
cd backend_nodejs
npm install
npm run check
npm run test:smoke
npm start
```


## Phase 17 — Branching Narrative Engine

The project now supports story flags, relationship scores, conditional dialogue, conditional chapter unlocks, delayed consequence messages, and multiple role endings. New fields are optional and old scenario/progress data remains compatible.

Run backend checks:

```bash
cd backend_nodejs
npm run check
npm run test:smoke
```

Run Flutter checks locally where Flutter is installed:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter run
```

## Phase 18 — Professional Simulation Layer

Phase 18 upgrades the game into a deeper professional simulation while preserving humor.

Added:

- role skill maps for all 8 professions
- beginner/intermediate/advanced skill levels
- at least 3 realistic workflows per role
- real-world constraints: time, budget, safety, ethics, client pressure, and documentation
- skill-based mini-game metadata
- professional glossary per role
- safe explanation cards after chapter outcomes
- mentor feedback based on player choices
- practical takeaways after each chapter
- high-stakes safety guardrails for medical, engineering, HR, privacy, and other professional domains

Key files:

```text
flutter_app/assets/game/professional/role_skill_maps.json
backend_nodejs/data/professional/role_skill_maps.json
flutter_app/lib/models/professional/role_skill_map_model.dart
flutter_app/lib/models/professional/professional_context_model.dart
flutter_app/lib/services/professional_simulation_service.dart
docs/phase18_professional_simulation_validation_report.md
```

Backend endpoint:

```text
GET /api/professional/skill-maps
```

The older scenario JSON format remains compatible. New professional fields are optional and have safe fallbacks.

## Phase 19 — Fun Activity System

The project now includes repeatable learning activities outside the main story chapters:

- Activity Hub
- Daily challenge
- Bug hunt
- Data cleanup race
- Ethical dilemma
- Client negotiation
- Weekly challenge placeholder
- Timer support
- Activity XP rewards
- Activity badge rewards
- Activity streaks
- Activity history saved in progress snapshot v6

Backend endpoint:

```text
GET /api/activities
```

Flutter local validation:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter run
```

Backend validation:

```bash
cd backend_nodejs
npm install
npm run check
npm run test:smoke
npm start
```

## Phase 20 — Flutter-Flame Hybrid Mini-games

Phase 20 adds a Flame-powered mini-game layer while keeping Flutter as the main UI shell.

New mini-games:

- Bug Hunt Room
- Data Cleanup Race
- Blueprint Safety Puzzle

Run locally:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter run
```

Backend checks:

```bash
cd backend_nodejs
npm run check
npm run test:smoke
npm start
```

## Phase 21 — Audio Experience

Phase 21 adds background music, sound effects, future-ready voice placeholders, subtitles, audio preloading, mute, and volume controls.

Key files:

```text
flutter_app/lib/services/audio_service.dart
flutter_app/lib/core/audio_registry.dart
flutter_app/lib/models/audio_config_model.dart
flutter_app/lib/widgets/audio_setting_tile.dart
flutter_app/assets/game/audio/
backend_nodejs/data/audio/audio_manifest.json
```

Backend endpoint:

```text
GET /api/audio/manifest
```

The included audio files are silent placeholders. Replace them with production audio using the same keys.

## Phase 22 — AI Mentor System

Phase 22 adds personalized, safe mentor feedback based on choices, score impact, weak areas, activity progress, and user preference.

Added:

- `MentorModel` and `MentorPreferenceModel`
- mentor selection screen
- four mentor styles: balanced, strict, funny, empathetic/safety-first
- optional roast mode controlled by the user
- safe feedback generation after each chapter
- weak area detection for discipline, communication, ethics, skill, and chaos control
- next activity suggestions
- weekly progress summary
- mentor preference saved in local progress and synced through Node.js progress API

Key files:

```text
flutter_app/assets/game/mentors/mentors.json
flutter_app/lib/models/mentor/mentor_model.dart
flutter_app/lib/services/mentor_service.dart
flutter_app/lib/screens/mentor_selection_screen.dart
flutter_app/test/phase22/mentor_system_test.dart
backend_nodejs/data/mentors/mentors.json
```

Backend endpoint:

```text
GET /api/mentors
```

Roast mode is always optional and only jokes about decision patterns, never the player.

## Phase 23 — Future Scope Architecture

The project now includes long-term expansion architecture:

- Feature flags
- Remote config defaults
- Content versioning
- Asset versioning
- Offline content cache strategy
- Analytics event structure
- Role plugin registry
- Scenario validation pipeline
- Safety review workflow
- Localization-ready text
- Premium/free content placeholders
- Multiplayer placeholders

Flutter config assets live in `flutter_app/assets/config/` and `flutter_app/assets/i18n/`.
Node.js exposes future-scope endpoints under `/api/config`, `/api/content`, `/api/assets`, `/api/role-plugins`, `/api/offline-cache`, `/api/safety-review`, `/api/scenario-validation`, and `/api/i18n/en`.

## Phase 24 — AI Adaptive Story Engine

Phase 24 adds behavior-aware story recommendations, adaptive dialogue injection, adaptive difficulty metadata, and draft-only AI side mission generation.

Key files:

- `flutter_app/lib/models/adaptive/user_behavior_summary_model.dart`
- `flutter_app/lib/models/adaptive/adaptive_story_model.dart`
- `flutter_app/lib/services/adaptive_story_service.dart`
- `flutter_app/lib/screens/adaptive_story_screen.dart`
- `flutter_app/assets/config/adaptive_story_prompt_template.md`
- `backend_nodejs/data/adaptive/adaptive_story_prompt_template.md`

Backend endpoints:

- `GET /api/adaptive/prompt-template`
- `POST /api/adaptive/drafts`
- `GET /api/admin/adaptive-drafts`
- `POST /api/admin/adaptive-drafts/:draftId/approve`
- `POST /api/admin/adaptive-drafts/:draftId/reject`

Adaptive drafts are never auto-published. Admin review is mandatory before any generated content can become playable scenario content.

## Phase 26 — Dynamic Skill Tree

Phase 26 adds role-wise skill trees and connects chapters, mini-games, coach recommendations, and progress persistence to skill mastery.

Added:

- `SkillTreeModel` and `SkillNodeModel`.
- Role-wise skill tree JSON in `flutter_app/assets/game/skill_trees/skill_trees.json`.
- Matching Node.js data in `backend_nodejs/data/skill_trees/skill_trees.json`.
- Chapter-level and mini-game-level `skillNodeIds`.
- `SkillTreeService` for loading trees, applying chapter/mini-game mastery, unlock rules, and weak-node recommendations.
- `SkillTreeScreen` from the role chapter list.
- `skillTreeProgressByRole` persisted in local progress and Node.js progress schema version 13.
- Backend endpoint: `GET /api/skill-trees`.
- Career coach weak skill-node recommendations.

Local validation:

```bash
cd backend_nodejs
npm run check
npm run test:smoke

cd ../flutter_app
flutter pub get
flutter analyze
flutter test
flutter run
```


## Phase 27 — Scenario Marketplace

Adds creator-driven scenario packs with metadata, publishing workflow, safety review, offline cache placeholders, featured packs, rating/review placeholders, and compatibility checks.

## Phase 28 — Multiplayer Team Simulation Mode

Phase 28 adds role-based team simulation while keeping solo mode unchanged.

Added:

- `TeamSessionModel` for room, participants, role selections, turn state, team decisions, score, flags, role impacts, and debrief.
- Flutter Team Simulation screen with create room, join by code/link, unique role selection, turn-based choices, live score card, and debrief entry.
- Flutter Team Debrief screen with collaboration, communication, speed, accuracy, ethics, key moments, and recommendations.
- Node.js team session APIs for room creation, join, role selection, start, decisions, session lookup, and room-code lookup.
- Team consequence engine using affected roles, role impact log, team flags, and decision history.
- `team_simulation` feature flag enabled in bundled and backend config.

Team APIs:

```text
GET  /api/team-sessions
POST /api/team-sessions
POST /api/team-sessions/join
GET  /api/team-sessions/code/:roomCode
GET  /api/team-sessions/:sessionId
POST /api/team-sessions/:sessionId/select-role
POST /api/team-sessions/:sessionId/start
POST /api/team-sessions/:sessionId/decisions
```

Validation:

```bash
cd backend_nodejs
npm run check
npm run test:smoke
```

Flutter validation should be run locally where Flutter is installed:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
```

## Phase 30 - Certification Engine

Phase 30 adds a feature-flagged assessment and certificate generation flow:

- Flutter Certification Engine screen from the home toolbar.
- Role-wise final assessments generated from the professional role skill maps.
- Timed assessment sessions with score, pass/fail, practical mini-game gate, and ethics gate.
- Backend certificate records with unique verification IDs.
- PDF certificate endpoint at `/api/certificates/:verificationId/pdf`.

Backend validation:

```bash
cd backend_nodejs
npm run check
npm run test:smoke
```

Flutter validation to run locally:

```bash
cd flutter_app
flutter analyze
flutter test
```

## Phase 31 — Corporate & College Edition

Phase 31 adds organization-based training support for colleges, companies, and coaching institutes.

Highlights:

- Organization and batch models
- Trainer, admin, trainee, and individual RBAC roles
- Scenario pack assignment system with due dates
- Trainee progress tracking
- Organization dashboard
- JSON/CSV report export
- Custom scenario pack access per organization
- Feature flag: `corporate_college_edition`

Backend validation:

```bash
cd backend_nodejs
npm run check
npm run test:smoke
```
## Phase 32 — AI Voice and Character Conversation

Phase 32 adds subtitle-first AI character conversation support with voice settings, placeholder TTS/STT hooks, safe scenario-bound replies, English/Hinglish/Hindi language modes, and text fallback if voice fails. The feature is available behind the `ai_voice_conversation` flag and does not replace normal individual gameplay.


## Phase 33 — Learning Analytics

Phase 33 adds privacy-safe analytics events, personal dashboards, admin aggregate dashboards, analytics disable controls, and capped local/backend event storage through the `learning_analytics` flag.

## Phase 34 — Monetization System

Phase 34 adds purchase-ready monetization architecture without real payment processing in development mode.

Highlights:

- `ProductModel`, product catalog, and premium/free content metadata
- Entitlement checks for premium content
- Purchase, subscription, certificate payment, and corporate license placeholders
- Premium pack preview
- Restore purchase placeholder
- `monetization_system` feature flag
- Development mode: no payment required; placeholders grant test entitlements only

Backend validation:

```bash
cd backend_nodejs
npm run check
npm run test:smoke
```

Flutter validation to run locally:

```bash
cd flutter_app
flutter analyze
flutter test
```

## Flame Engine Upgrade

The Flutter game layer now targets:

```yaml
flame: ^1.37.0
```

After extracting the project, refresh Flutter dependencies before running analysis or tests:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
```

The existing hybrid mini-game architecture remains unchanged: Flutter manages application screens and Flame runs the real-time mini-game canvas.

## Phase 36 — Game Visual & Animation Overhaul

Phase 36 introduces the first production-style visual vertical slice using `flame: ^1.37.0`.

Implemented:

- Redesigned role cards with game-style lighting, progress rings, depth, and haptic feedback.
- Replaced the crowded home toolbar with a compact app bar and responsive Game Hub.
- Added a cinematic role-selection hero panel.
- Persistent visual quality modes: Performance, Balanced, and Cinematic.
- Flame-powered cinematic atmosphere layer with particles, scanlines, light beams, mood colours, and vignette effects.
- Larger animated character portraits with entrance, emotion, idle-breathing, and glow motion.
- Game-style decision cards and a full-screen consequence impact sequence.
- Developer Chapter 1 now launches the polished Flame Bug Hunt Room instead of the basic form mini-game.
- Bug Hunt supports direct taps inside the Flame canvas, animated incident cards, combo feedback, tap bursts, warning timer, and live incident HUD.
- Reduced-motion and lower-effects modes remain available.
- Feature flag: `game_visual_overhaul`.

Backend validation:

```bash
cd backend_nodejs
npm run check
npm run test:smoke
```

Flutter validation to run locally with Flutter 3.41.0 or newer:

```bash
cd flutter_app
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```
