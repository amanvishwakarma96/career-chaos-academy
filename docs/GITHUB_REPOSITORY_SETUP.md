# GitHub Repository Setup

## Recommended repository details

```text
Repository name: career-chaos-academy
Visibility: Private
Initialize with README: No
Initialize with .gitignore: No
License: None
```

Suggested description:

```text
A gamified career-learning and job-readiness platform built with Flutter, Flame and Node.js, featuring role-based scenarios, cinematic storytelling, mini-games, interview preparation, certifications, multiplayer simulations, analytics and corporate training.
```

Suggested topics:

```text
flutter
dart
flame-engine
nodejs
edtech
gamification
game-based-learning
career-development
interview-preparation
serious-games
learning-analytics
multiplayer
```

## Initial push

Create an empty private repository on GitHub, then run from the project root:

```bash
git init
git branch -M main
git add .
git commit -m "chore: initialize Career Chaos Academy Phase 36"
git remote add origin https://github.com/<OWNER>/career-chaos-academy.git
git push -u origin main
```

Use SSH instead when configured:

```bash
git remote add origin git@github.com:<OWNER>/career-chaos-academy.git
```

## Branch protection

After the first push, protect `main`:

- Require a pull request before merging.
- Require at least one approval when multiple contributors are active.
- Require backend and Flutter CI checks.
- Require conversation resolution.
- Block force pushes and branch deletion.
- Restrict direct pushes for shared/team repositories.

## Suggested branching model

- `main`: stable, releasable source.
- `develop`: optional integration branch when parallel work increases.
- `feature/*`: new product or gameplay work.
- `fix/*`: bugs.
- `content/*`: scenario and asset changes.
- `security/*`: hardening and vulnerability fixes.

For a small team, use trunk-based development with short-lived branches and merge directly into protected `main` through pull requests.

## GitHub Actions

Included workflows:

```text
.github/workflows/backend-ci.yml
.github/workflows/flutter-ci.yml
```

Before requiring Flutter CI, confirm the stable Flutter channel satisfies the minimum version in `pubspec.yaml` and that all tests pass on GitHub-hosted runners.

## Repository secrets

Add secrets only when provider integrations are ready. Possible future secrets include:

```text
SENTRY_DSN
FIREBASE_SERVICE_ACCOUNT
ANDROID_KEYSTORE_BASE64
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
ANDROID_STORE_PASSWORD
APPLE_CERTIFICATE_BASE64
APPLE_CERTIFICATE_PASSWORD
APP_STORE_CONNECT_API_KEY
PAYMENT_PROVIDER_SECRET
AI_PROVIDER_API_KEY
```

Never place these values in workflow YAML, source files, issue comments, or pull request descriptions.
