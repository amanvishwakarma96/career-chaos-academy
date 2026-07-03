# iOS Release Preparation

## Generate platform files if missing

```bash
flutter create . --platforms=ios --org com.careerchaos
```

Recommended bundle identifier:

```text
com.careerchaos.academy
```

## Generate icons and splash

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Open in Xcode

```bash
open ios/Runner.xcworkspace
```

Configure:

- Bundle identifier
- Apple developer team
- Signing certificate
- Deployment target
- App display name
- Privacy manifest if required by enabled SDKs

## Archive

Use Xcode Product > Archive, then upload to TestFlight.
