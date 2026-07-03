# Phase 12 - Release Preparation Summary

## Source-level status

Phase 12 release preparation has been added at source level. Runtime build validation is pending because the execution environment does not include Flutter, Dart, or .NET SDK.

## Added

- App branding assets
- Launcher icon generator config
- Native splash screen config
- Version updated to `1.0.0+12`
- App metadata constants
- Crash reporting hooks through Sentry
- Analytics hooks through Firebase Analytics
- Privacy policy draft
- Terms and conditions draft
- Store listing draft
- Android/iOS/web release guides
- Release checklist
- Release helper scripts

## Local build gate

Run locally:

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter analyze
flutter test
```

Android release:

```bash
flutter build appbundle --release
```

iOS release:

```bash
open ios/Runner.xcworkspace
```

Web release:

```bash
flutter build web --release
```

## Important blocker

The current project archive does not include generated Flutter platform folders. If missing locally, run:

```bash
flutter create . --platforms=android,ios,web --org com.careerchaos
```

Then verify package/bundle ID is configured as:

```text
com.careerchaos.academy
```
