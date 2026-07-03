# Crash Reporting and Analytics Setup

Phase 12 adds release monitoring hooks through `ReleaseMonitoringService`.

## Crash reporting

Crash reporting is prepared using Sentry and is disabled by default.

Enable it during build/run:

```bash
flutter run \
  --dart-define=CAREER_CHAOS_ENABLE_SENTRY=true \
  --dart-define=CAREER_CHAOS_SENTRY_DSN=https://your-sentry-dsn
```

For release:

```bash
flutter build appbundle --release \
  --dart-define=CAREER_CHAOS_ENABLE_SENTRY=true \
  --dart-define=CAREER_CHAOS_SENTRY_DSN=https://your-sentry-dsn
```

## Analytics

Analytics is prepared using Firebase Analytics and is disabled by default.

Before enabling:

1. Create a Firebase project.
2. Add Android/iOS/web apps.
3. Run FlutterFire configuration.
4. Add generated Firebase options/config files.
5. Confirm platform setup in Android/iOS/web.

Enable it only after FlutterFire setup:

```bash
flutter run \
  --dart-define=CAREER_CHAOS_ENABLE_FIREBASE_ANALYTICS=true
```

## Events currently prepared

- `app_start`
- `chapter_completed`
- `mini_game_completed`
- Firebase screen view tracking through `FirebaseAnalyticsObserver` when analytics is enabled.

## Safety rule

Do not log sensitive data such as passwords, payment data, medical details, private notes, or exact personal identifiers.
