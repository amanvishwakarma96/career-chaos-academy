# Phase 12 Release Checklist

## Pre-build

- [ ] Run `flutter create . --platforms=android,ios,web --org com.careerchaos` if platform folders are missing.
- [ ] Confirm app package ID is `com.careerchaos.academy` or update it consistently.
- [ ] Replace placeholder support email in legal docs.
- [ ] Replace store listing placeholder URLs.
- [ ] Configure real Sentry DSN if crash reporting is required.
- [ ] Configure Firebase project and FlutterFire options if analytics is required.
- [ ] Run `flutter pub get`.
- [ ] Run app icon generation.
- [ ] Run splash generation.

## QA gate

- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run backend tests with `dotnet test`.
- [ ] Complete manual regression checklist in `docs/qa/regression_checklist.md`.
- [ ] Confirm no critical bugs remain.

## Android release

- [ ] Create upload keystore.
- [ ] Configure signing in Android Gradle files.
- [ ] Build app bundle: `flutter build appbundle --release`.
- [ ] Test release APK/AAB on a real device.
- [ ] Upload to Play Console internal testing.

## iOS release

- [ ] Open iOS project in Xcode.
- [ ] Configure bundle ID, signing team, deployment target, and capabilities.
- [ ] Archive release build.
- [ ] Upload to TestFlight.

## Web release

- [ ] Build web: `flutter build web --release`.
- [ ] Test hosted build.
- [ ] Confirm privacy/terms links are available.

## Store submission

- [ ] Upload app icon and screenshots.
- [ ] Add short and full descriptions.
- [ ] Add privacy policy URL.
- [ ] Complete data safety / privacy nutrition forms.
- [ ] Submit internal review before public release.
