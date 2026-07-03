#!/usr/bin/env bash
set -euo pipefail

echo "== Career Chaos Academy Phase 12 release preparation =="

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter CLI not found. Install Flutter before running this script."
  exit 1
fi

echo "Checking for platform folders..."
if [ ! -d android ] && [ ! -d ios ] && [ ! -d web ]; then
  echo "No Flutter platform folders found. Generate them first, for example:"
  echo "flutter create . --platforms=android,ios,web --org com.careerchaos"
  exit 1
fi

flutter pub get

echo "Generating launcher icons..."
dart run flutter_launcher_icons

echo "Generating splash screen..."
dart run flutter_native_splash:create

echo "Running Flutter analysis and tests..."
flutter analyze
flutter test

echo "Release preparation completed. Build Android/iOS/web using docs/release/*.md."
