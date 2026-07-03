#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter CLI not found."
  exit 1
fi

flutter pub get
flutter analyze
flutter test
flutter build appbundle --release \
  --dart-define=CAREER_CHAOS_ENABLE_SENTRY=${CAREER_CHAOS_ENABLE_SENTRY:-false} \
  --dart-define=CAREER_CHAOS_SENTRY_DSN=${CAREER_CHAOS_SENTRY_DSN:-} \
  --dart-define=CAREER_CHAOS_ENABLE_FIREBASE_ANALYTICS=${CAREER_CHAOS_ENABLE_FIREBASE_ANALYTICS:-false} \
  --dart-define=CAREER_CHAOS_API_BASE_URL=${CAREER_CHAOS_API_BASE_URL:-}
