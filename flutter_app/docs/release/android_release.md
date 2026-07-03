# Android Release Preparation

## Generate platform files if missing

```bash
flutter create . --platforms=android --org com.careerchaos
```

Then update Android application ID to:

```text
com.careerchaos.academy
```

## Generate icons and splash

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Build debug smoke test

```bash
flutter run
```

## Build release app bundle

```bash
flutter build appbundle --release \
  --dart-define=CAREER_CHAOS_ENABLE_SENTRY=false \
  --dart-define=CAREER_CHAOS_ENABLE_FIREBASE_ANALYTICS=false
```

## Build release APK for device testing

```bash
flutter build apk --release
```

## Signing note

Do not commit real keystore files or passwords. Use `key.properties` locally only.
