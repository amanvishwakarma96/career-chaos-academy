# Career Chaos Academy — Visual Asset Naming Convention

## Folder structure

```text
assets/game/
├── backgrounds/
├── characters/
├── props/
├── badges/
├── lottie/
├── rive/
└── audio/
```

Legacy `assets/cinematic/...` paths are still supported for backward compatibility, but new content should use `assets/game/...` plus `AssetRegistry` keys.

## Asset keys

Scenario JSON should reference stable keys instead of direct file paths whenever possible.

| Type | Key prefix | Example key | Example file |
|---|---|---|---|
| Background | `bg_` | `bg_office_morning` | `assets/game/backgrounds/office_morning.png` |
| Character | `char_` | `char_developer_worried` | `assets/game/characters/developer_worried.png` |
| Prop | `prop_` | `prop_laptop_error` | `assets/game/props/laptop_error.png` |
| Badge | `badge_` | `badge_safe_escalation` | `assets/game/badges/safe_escalation.png` |
| Lottie | `lottie_` | `lottie_badge_unlock` | `assets/game/lottie/badge_unlock.json` |
| Rive | `rive_` | `rive_rank_meter` | `assets/game/rive/rank_meter.riv` |
| Audio | `sfx_` / `music_` | `sfx_notification_ping` | `assets/game/audio/notification_ping.mp3` |

## File naming rules

- Use lowercase snake_case only.
- Avoid spaces, special characters, and version numbers in runtime filenames.
- Include role/context/emotion where useful: `developer_worried.png`, `doctor_calm.png`.
- Keep keys stable even if the underlying file is replaced.
- Prefer asset keys in scenario JSON; direct `assets/...` paths are allowed only for compatibility.
- Remote URLs are supported by the registry for future CDN usage, but production content should be reviewed before using external assets.

## Scenario JSON example

```json
{
  "backgroundImage": "bg_office_morning",
  "characterImage": "char_developer_worried",
  "dialogues": [
    {
      "speaker": "Senior Dev",
      "emotion": "serious",
      "text": "Rollback first, hero speech later.",
      "characterImage": "char_senior_serious"
    }
  ]
}
```
