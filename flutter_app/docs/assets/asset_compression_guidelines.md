# Career Chaos Academy — Asset Compression Guidelines

## Background images

- Recommended size: 1280×720 for mobile-first cinematic backgrounds.
- Use WebP for production when platform support is confirmed; PNG placeholders are acceptable during prototyping.
- Keep each background under 250 KB when possible.
- Avoid text baked into background images so localization remains possible.

## Character portraits

- Recommended size: 512×512 or 768×1024 depending on full-body/portrait style.
- Use transparent PNG/WebP for characters.
- Keep each character state under 150 KB when possible.
- Use separate files for important emotions: `calm`, `worried`, `serious`, `panic`, `relieved`.

## Props and badges

- Recommended size: 256×256 for props and badges.
- Keep each under 80 KB.
- Use SVG only after confirming rendering support; PNG/WebP is safest for Flutter runtime.

## Lottie and Rive

- Keep animation duration short: 1–3 seconds for UI rewards.
- Remove unused layers, hidden objects, and unused artboards.
- Keep Lottie files under 150 KB and Rive files under 300 KB where possible.

## Audio

- SFX: MP3/AAC/OGG, 0.5–2 seconds, under 80 KB.
- Music loops: short seamless loops, under 1 MB for mobile builds.
- Always provide a mute setting before enabling audio globally.

## Build-size checklist

Before release:

```bash
flutter build apk --analyze-size
flutter build appbundle --analyze-size
flutter build web --analyze-size
```

Review assets if the app bundle grows quickly. Replace large PNGs with WebP where possible.
