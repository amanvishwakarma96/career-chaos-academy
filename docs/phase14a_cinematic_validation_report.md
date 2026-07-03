# Career Chaos Academy — Phase 14A Cinematic Narrative Validation Report

## Scope
Phase 14A upgrades the existing Phase 13 consequence-driven game into a cinematic narrative experience while keeping old simple scenario JSON backward compatible.

## Previous Phase Validation
Source-level validation confirmed:

- Flutter app source exists.
- Clean architecture exists.
- JSON scenario system exists.
- Multi-chapter progression exists.
- Local progress saving exists.
- XP, badges, and ranks exist.
- Mini-games exist.
- UI polish exists.
- Node.js backend exists.
- Web admin panel exists.
- AI content-generation format exists.
- QA and release foundations exist.

Runtime Flutter validation remains pending in this sandbox because Flutter/Dart are unavailable.

## Phase 14A Implementation

### Flutter
Added cinematic schema support:

- `DialogueSceneModel`
- `DialogueLineModel`
- `ScenarioModel.scenes`
- `ScenarioModel.hasCinematicScenes`

Added cinematic gameplay screen:

- `DialogueSceneScreen`

The screen supports:

- background image per scene
- character portrait per dialogue/emotion
- emotion-based dialogue styling
- typing text effect
- skip dialogue option
- auto-play dialogue option
- dramatic choice screen after dialogue
- mini-game gate after cinematic scenes
- consequence message after choice

Old chapters without `scenes` still use the existing `ScenarioScreen` fallback.

### Scenario Data
Added cinematic scenes to:

- Developer: `developer_login_button_disaster`
- Doctor: `doctor_sneeze_storm`

The Developer chapter includes two scenes with changing backgrounds and character portraits. The Doctor chapter includes safety-focused cinematic dialogue with medical safety framing.

### Assets
Added placeholder cinematic asset folders:

- `assets/cinematic/backgrounds/`
- `assets/cinematic/characters/`

These are registered in `pubspec.yaml`. The UI also has fallback gradients if an image is missing.

### Backend / Admin
Updated Node.js validation to accept optional `scenes` fields:

- `scenes`
- `dialogues`
- `speaker`
- `emotion`
- `backgroundImage`
- `characterImage`
- `soundEffect`
- `transitionType`

Updated the admin panel with a Phase 14A cinematic scenes editor and client-side validation before saving scenario JSON.

### Tests
Added Flutter test coverage for:

- old non-cinematic JSON compatibility
- new cinematic scene parsing
- dialogue/emotion/image/transition field parsing

## Validation Results

| Validator Item | Status |
|---|---:|
| Scenario JSON supports scenes | Passed |
| Dialogue screen source exists | Passed |
| Character image changes with emotion | Source-level passed |
| Background image changes by scene | Source-level passed |
| Choices appear after dialogue | Source-level passed |
| Old scenario format still works | Passed |
| Progress saving still uses existing service | Passed |
| Mini-games still work after cinematic scenes | Source-level passed |
| Node.js backend accepts scenes | Passed |
| Admin panel can edit scenes | Passed |
| Backend smoke test | Passed |
| Flutter runtime validation | Pending local Flutter SDK |

## Data Counts After Phase 14A

- Roles: 8
- Chapters: 27
- Choices: 79
- Outcomes: 79
- Mini-games: 6
- Cinematic scenes: 4
- Cinematic dialogue lines: 8

## Commands Run in Sandbox

```bash
cd backend_nodejs
npm run check
npm run test:smoke
```

Result: passed.

## Local Flutter Validation Required

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter run
```

With Node API:

```bash
flutter run --dart-define=CAREER_CHAOS_API_BASE_URL=http://10.0.2.2:5085
```

Flutter web:

```bash
flutter run -d chrome --dart-define=CAREER_CHAOS_API_BASE_URL=http://localhost:5085
```
