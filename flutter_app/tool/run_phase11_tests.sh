#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "== Flutter checks =="
flutter pub get
flutter analyze
flutter test --coverage

echo "== Backend checks =="
dotnet restore backend/CareerChaosAcademy.Api/CareerChaosAcademy.Api.csproj
dotnet test backend/CareerChaosAcademy.Api.Tests/CareerChaosAcademy.Api.Tests.csproj --collect:"XPlat Code Coverage"

echo "== Manual regression =="
echo "Complete docs/qa/regression_checklist.md before release sign-off."
