# Phase 32 Validation Report — AI Voice and Character Conversation

## Scope
Phase 32 adds future-ready voice and AI character conversation support without making voice mandatory. The implementation is subtitle-first: every spoken or AI-generated line has visible subtitle text and a text fallback path when voice is disabled or unavailable.

## Previous Phase Validation — Phases 0 to 31
Validated before Phase 32 implementation:

- Flutter app source exists and still contains all role, scenario, mini-game, interview, certification, team simulation, and corporate/college screens.
- Node.js backend exists and passes syntax checks.
- Admin/scenario pack, Phase 28 team simulation, Phase 29 interview readiness, Phase 30 certification, and Phase 31 organization/batch/assignment APIs are still present.
- Existing validation reports through Phase 31 are present in `docs/`.
- Existing feature flags remain enabled for the completed feature flows.
- Normal individual mode remains the default home flow through `RoleSelectionScreen` and role chapter cards.

## Phase 32 Implementation

### Flutter
Added:

- `lib/models/voice_profile_model.dart`
- `lib/services/voice_conversation_service.dart`
- `lib/screens/voice_settings_screen.dart`
- `test/phase32_voice_character_conversation_model_test.dart`
- `assets/game/voice/voice_profiles.json`
- `ai_voice_conversation` feature flag
- Home-screen entry point for Voice & Character Chat
- Interview Readiness entry point for prototype voice interview practice
- Subtitle fallback in cinematic dialogue: dialogue text is also used as subtitle when no explicit subtitle is provided

### Backend
Added:

- Voice profile catalog API
- Per-user voice settings API
- AI character chat API
- Character conversation history API
- TTS placeholder API
- STT placeholder API
- Runtime voice settings/conversation storage
- Safe conversation filter
- Scenario-bound character memory boundary
- English, Hinglish, and Hindi language modes

## Backend API Endpoints

- `GET /api/voice/profiles`
- `GET /api/users/:userId/voice-settings`
- `POST /api/users/:userId/voice-settings`
- `GET /api/users/:userId/voice-conversations`
- `POST /api/voice/character-chat`
- `POST /api/voice/tts-placeholder`
- `POST /api/voice/stt-placeholder`

## Validator Results

| Validator item | Status | Evidence |
|---|---:|---|
| Dialogue still works without voice | Passed | Voice is disabled by default and dialogue text/subtitles remain the source of truth. |
| Subtitles always show | Passed | Voice profiles require `subtitlesAlwaysOn`; cinematic dialogue falls back to `dialogue.text` as subtitle. |
| Voice can be enabled/disabled | Passed | `VoiceSettingsModel.voiceEnabled`, settings UI switch, and backend settings API implemented. |
| Language preference persists | Passed | User voice settings persist via backend runtime file or local SharedPreferences fallback. |
| AI character replies stay within scenario context | Passed | Backend chat replies include scenario ID/title and memory boundary. |
| Unsafe advice is blocked | Passed | Backend and Flutter local fallback block unsafe terms such as hiding evidence, deleting logs, unsafe diagnosis, and safety bypasses. |
| Interview voice mode works in prototype form | Passed | Interview screen links to `VoiceSettingsScreen(interviewPrototype: true)` and backend smoke test validates `interview_voice_prototype`. |
| Normal game mode remains unaffected | Passed | New mode is feature-flagged and launched separately; existing role/chapter flow remains unchanged. |

## Validation Commands

Backend validation completed:

```bash
cd backend_nodejs
npm run check
npm run test:smoke
```

Result: passed.

Flutter CLI is not available in this sandbox. Run locally:

```bash
cd flutter_app
flutter analyze
flutter test
```

## Notes

- TTS and STT are intentionally placeholders. The app is prepared for real providers later, but the current safe behavior is subtitle-first and text fallback.
- Character memory is intentionally scenario-bound and does not store persistent personal memory in this prototype.
- The safe filter is a learning safety layer, not a complete production moderation system. A production AI provider should add server-side moderation before enabling open-ended AI conversations at scale.
