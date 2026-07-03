# Flame Engine Dependency Upgrade

## Change
- Updated Flutter dependency from `flame: ^1.29.0` to `flame: ^1.37.0`.
- Existing `FlameGame`, `GameWidget`, render loop, timer, and mini-game factory code were retained.
- Added `flutter: ">=3.41.0"` to the project environment because Flame 1.36+ requires Flutter 3.41.0 or newer.

## Local verification required
Flutter is not installed in the packaging environment. Run:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
```

Resolve and commit the generated `pubspec.lock` in the application repository after successful dependency resolution.
