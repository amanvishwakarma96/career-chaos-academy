# Career Chaos Academy Flutter App

The Flutter client provides the learner-facing application, dashboards, local-first content, progress persistence, settings, cinematic story screens, and Flame-powered mini-games.

## Current visual milestone

**Phase 36 — Game Visual & Animation Overhaul vertical slice**

The primary review path is:

```text
Role Selection → Developer → Chapter 1 → Cinematic Scene → Choice → Consequence → Bug Hunt Room
```

The app uses:

```yaml
flame: ^1.37.0
```

## Requirements

- Flutter 3.41.0 or newer
- Dart `>=3.3.0 <4.0.0`
- Android Studio / Xcode / Chrome depending on target

## Setup

```bash
flutter pub get
flutter analyze
flutter test
```

If platform folders are absent from the source delivery:

```bash
flutter create .
flutter pub get
```

Review package identifiers, platform permissions, signing, Firebase setup, icons, and splash files after generating platforms.

## Run

Without backend:

```bash
flutter run
```

Android emulator with local backend:

```bash
flutter run \
  --dart-define=CAREER_CHAOS_API_BASE_URL=http://10.0.2.2:5085
```

Web with local backend:

```bash
flutter run -d chrome \
  --dart-define=CAREER_CHAOS_API_BASE_URL=http://localhost:5085
```

The app is local-first. Supported content and progress flows fall back to bundled assets and local storage if the API is unavailable.

## Optional monitoring defines

```text
SENTRY_DSN
ENABLE_SENTRY
ENABLE_FIREBASE_ANALYTICS
```

Do not enable these until native provider configuration and privacy review are complete.

## Source layout

```text
lib/
├── app/                 # App shell, theme and navigation
├── content_generation/  # Scenario generation/review tooling
├── core/                # Shared registries and infrastructure
├── data/                # Content repositories and asset paths
├── games/               # Flame game classes and components
├── models/              # Domain and persistence models
├── screens/             # Flutter screens
├── services/            # API, progress, audio, config, security, analytics
└── widgets/              # Reusable UI components
```

## Flutter + Flame responsibility split

Use Flutter for:

- App navigation and responsive layouts.
- Forms, dashboards, settings, reports, and admin-like tools.
- Dialogue and HUD overlays that need accessibility and rich text.

Use Flame for:

- Game-loop animation.
- Direct canvas interactions.
- Timers, target movement, particles, and real-time effects.
- Mini-game state and cinematic atmosphere layers.

Do not move every application screen into Flame. Preserve the hybrid boundary.

## Assets

Assets are grouped under:

```text
assets/branding/
assets/cinematic/
assets/game/
assets/scenarios/
assets/config/
assets/i18n/
```

For new game assets:

- Optimize image dimensions and compression.
- Preload gameplay-critical assets.
- Prefer sprite sheets/atlases for frame animations.
- Keep stable asset keys where registry support exists.
- Test Performance, Balanced, Cinematic, and reduced-motion modes.

## Quality checks

```bash
flutter pub get
flutter analyze
flutter test
```

For visual changes, also test:

- Narrow Android phone.
- Low-end Android device.
- iPhone simulator/device.
- Flutter web.
- Text scaling and accessibility.
- Reduced motion.
- Performance and Cinematic quality modes.

## Release preparation

Generate branding resources locally:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Never commit signing credentials, keystores, `.env` files, service accounts, or production provider secrets.
