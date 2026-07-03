# Career Chaos Academy — Phase 21 Audio Guidelines

## Folder

Audio assets live in:

```text
assets/game/audio/
```

Use short lowercase snake_case names:

```text
bgm_office_light.wav
notification_ping.wav
choice_select.wav
voice_placeholder.wav
```

## JSON Usage

Scene audio:

```json
{
  "audio": {
    "backgroundMusic": "bgm_office_light",
    "soundEffect": "notification_ping",
    "loopBackgroundMusic": true,
    "musicVolume": 0.45
  }
}
```

Dialogue audio and future voice support:

```json
{
  "speaker": "Senior Dev",
  "text": "Evidence first.",
  "audio": {
    "voiceClip": "voice_placeholder",
    "subtitle": "Evidence first.",
    "voiceVolume": 0.75
  }
}
```

## Performance Rules

- Keep SFX below 100 KB where possible.
- Keep looping BGM compressed and short-loop friendly.
- Avoid starting multiple BGM tracks at once; use scene-level BGM replacement.
- Always include subtitles for future voice clips.
- Missing audio should be safe. Gameplay must continue silently.

## Production Replacement

The included WAV files are silent placeholders. Replace them with optimized production audio using the same filenames or update `AudioRegistry` keys.
