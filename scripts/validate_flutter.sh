#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/flutter_app"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not installed or is not available on PATH." >&2
  exit 1
fi

flutter pub get
flutter analyze
flutter test
