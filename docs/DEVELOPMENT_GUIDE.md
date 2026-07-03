# Development Guide

## First-time setup

```bash
git clone <YOUR_REPOSITORY_URL>
cd career-chaos-academy
```

### Backend

```bash
cd backend_nodejs
cp .env.example .env
npm run check
npm run test:smoke
npm start
```

The backend currently uses Node.js built-in modules and has no external runtime dependencies.

### Flutter

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
```

If platform folders are missing:

```bash
flutter create .
flutter pub get
```

Do not overwrite existing `lib/`, `assets/`, `test/`, `pubspec.yaml`, or project documentation.

## Running against the backend

Android emulator:

```bash
flutter run --dart-define=CAREER_CHAOS_API_BASE_URL=http://10.0.2.2:5085
```

Physical device on the same network:

```bash
flutter run --dart-define=CAREER_CHAOS_API_BASE_URL=http://<YOUR_COMPUTER_LAN_IP>:5085
```

Web:

```bash
flutter run -d chrome --dart-define=CAREER_CHAOS_API_BASE_URL=http://localhost:5085
```

## Adding or changing Flutter dependencies

1. Update `flutter_app/pubspec.yaml`.
2. Run `flutter pub get`.
3. Commit the generated `pubspec.lock` because this is an application repository.
4. Run `flutter analyze` and `flutter test`.
5. Verify Android, iOS, and web compatibility for plugins with native code.

## Adding game assets

1. Place assets in the correct folder under `flutter_app/assets/`.
2. Use stable asset keys through the registry where supported.
3. Update `pubspec.yaml` only when a new top-level asset directory is introduced.
4. Preload gameplay-critical sprites and audio.
5. Test Performance, Balanced, Cinematic, and reduced-motion modes.
6. Avoid committing unnecessarily large source exports.

## Adding a scenario

1. Add or update role JSON under `flutter_app/assets/scenarios/`.
2. Mirror backend scenario data under `backend_nodejs/data/scenarios/` when required.
3. Run the scenario validator.
4. Confirm skill node, professional context, safety status, and compatibility metadata.
5. Verify old scenario fields remain supported.
6. Complete human safety review before publish.

## Backend runtime data

Files under `backend_nodejs/data/runtime/` are generated locally and ignored by Git. To reset local prototype state:

```bash
find backend_nodejs/data/runtime -type f \
  ! -name '.gitkeep' \
  ! -name 'README.md' \
  -delete
```

The backend recreates required runtime files as flows are exercised.

## Visual development checklist

For Phase 36 or later game visuals:

- Maintain readable text over moving backgrounds.
- Preserve subtitles.
- Avoid required interactions that depend only on color.
- Respect reduced motion.
- Preload assets to avoid first-use jank.
- Keep Flutter overlays and Flame state synchronized.
- Test low-end Android devices and web rendering.
- Profile frame build/raster time before approving a visual rollout.

## Pull request evidence

Visual changes should include:

- Before/after screenshots.
- A short recording for animation changes.
- Target device and resolution.
- Performance mode tested.
- Reduced-motion behavior.
- Test command output.
