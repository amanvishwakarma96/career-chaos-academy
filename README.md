# Career Chaos Academy

Career Chaos Academy is a gamified career-learning and job-readiness platform built with **Flutter**, **Flame**, and **Node.js**. It combines role-based stories, cinematic dialogue, interactive decisions, mini-games, interview preparation, assessments, certificates, team simulations, learning analytics, AI mentor prototypes, and organization training workflows.

> **Project status:** advanced prototype / pre-beta. The latest visual vertical slice is Phase 36 and uses `flame: ^1.37.0` for cinematic atmosphere and the Developer Chapter 1 Bug Hunt experience.

## Highlights

- Eight career-role learning paths driven by JSON scenarios.
- Branching choices, consequence flags, reputation, endings, and debriefs.
- Flutter + Flame hybrid architecture for application UI and real-time mini-games.
- Cinematic dialogue with animated characters, subtitles, audio hooks, particles, and visual-quality modes.
- Multiplayer team simulation with role selection, turns, team consequences, scoring, and debrief.
- Interview readiness, timed assessments, certificates, and verification records.
- Corporate and college edition with organizations, batches, assignments, progress, RBAC, and exports.
- Scenario marketplace, skill trees, learning analytics, monetization placeholders, and feature flags.
- Production-readiness controls including secure token storage, request validation, rate limiting, admin audit logs, moderation, prompt-abuse checks, backups, monitoring hooks, and privacy rules.

## Technology stack

| Area | Technology |
|---|---|
| Mobile / Web client | Flutter and Dart |
| Real-time game layer | Flame `^1.37.0` |
| Animation and audio | Flutter animation APIs, Lottie, Flame, Audioplayers |
| Local storage | SharedPreferences and Flutter Secure Storage |
| Monitoring placeholders | Sentry and Firebase |
| Backend | Node.js `>=18`, CommonJS, built-in HTTP server |
| Admin panel | Static HTML/CSS/JavaScript served by Node.js |
| Content | Versioned JSON assets and runtime JSON prototype storage |

## Repository structure

```text
career-chaos-academy/
├── .github/                  # CI workflows and GitHub templates
├── backend_nodejs/           # API, admin panel, content data, security layer
├── docs/                     # Architecture, roadmap, security and phase reports
├── flutter_app/              # Flutter client and Flame mini-games
├── scripts/                  # Local validation helpers
├── .editorconfig
├── .gitattributes
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
└── README.md
```

## Prerequisites

- Flutter **3.41.0 or newer**
- Dart SDK compatible with `>=3.3.0 <4.0.0`
- Node.js **18 or newer**; Node.js 20 LTS is recommended
- Git
- Android Studio / Xcode / Chrome depending on the target platform

## Quick start

### 1. Clone and enter the repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd career-chaos-academy
```

### 2. Start the Node.js backend

```bash
cd backend_nodejs
cp .env.example .env
set -a
source .env
set +a
```

The current backend intentionally has no external runtime dependencies. On Windows, load the same values through PowerShell, your IDE, Docker, or a process manager. Then run:

```bash
npm ci
npm run check
npm run test:smoke
npm start
```

The API and admin panel run at:

```text
API:   http://localhost:5085/api/health
Admin: http://localhost:5085/admin/
```

Development-only admin defaults are documented in `backend_nodejs/.env.example`. Replace them before sharing or deploying the application.

### 3. Run the Flutter app

In another terminal:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
```

Android emulator:

```bash
flutter run \
  --dart-define=CAREER_CHAOS_API_BASE_URL=http://10.0.2.2:5085
```

Flutter web:

```bash
flutter run -d chrome \
  --dart-define=CAREER_CHAOS_API_BASE_URL=http://localhost:5085
```

The client is local-first. If the backend is unavailable, supported flows fall back to bundled JSON content and local progress storage.

### Missing platform folders

This delivery focuses on source code. If `android/`, `ios/`, `web/`, `windows/`, `macos/`, or `linux/` folders are not present, generate them without replacing `lib/` or assets:

```bash
cd flutter_app
flutter create .
flutter pub get
```

Review generated identifiers, signing settings, Firebase files, icons, and splash configuration before release.

## Phase 36 visual vertical slice

Use this path for the first visual review:

```text
Role Selection → Developer → Chapter 1 → Cinematic Scene → Choice → Consequence → Bug Hunt Room
```

Phase 36 includes:

- Game-style role cards and responsive Game Hub.
- Cinematic Flame atmosphere with particles, lighting, scanlines, mood effects, and vignette.
- Character entrance, idle breathing, emotion shake, focus zoom, and glow.
- Animated decision cards and consequence feedback.
- A polished Bug Hunt Room with direct canvas taps, combos, target motion, timer pressure, and tap bursts.
- Performance, Balanced, and Cinematic quality modes.
- Reduced-motion compatibility.

## Configuration

### Flutter build-time values

```text
CAREER_CHAOS_API_BASE_URL
SENTRY_DSN
ENABLE_SENTRY
ENABLE_FIREBASE_ANALYTICS
```

Only configure real monitoring providers after their native platform setup has been completed.

### Feature flags

Bundled Flutter flags:

```text
flutter_app/assets/config/feature_flags.json
```

Backend flags:

```text
backend_nodejs/data/config/feature_flags.json
```

Keep both files aligned when changing a cross-platform feature.

### Backend environment values

See:

```text
backend_nodejs/.env.example
```

Never commit `.env`, credentials, signing keys, service-account files, access tokens, or production runtime data.

## Validation

Backend:

```bash
cd backend_nodejs
npm run check
npm run test:smoke
```

Flutter:

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
```

Combined helper:

```bash
./scripts/validate_all.sh
```

GitHub Actions repeat backend and Flutter checks for pushes and pull requests.

## Security and privacy

- Keep the GitHub repository **private** until production credentials, payment providers, AI providers, and enterprise identity integrations are complete.
- Runtime JSON files are excluded from Git because they may contain progress, sessions, analytics, reports, audit logs, or generated content.
- Development credentials are placeholders only.
- User export, deletion, anonymization, production database migration, distributed rate limiting, and managed encrypted backups remain production launch gates.

Read:

- [`SECURITY.md`](SECURITY.md)
- [`docs/phase35_privacy_data_retention_rules.md`](docs/phase35_privacy_data_retention_rules.md)
- [`docs/phase35_production_deployment_checklist.md`](docs/phase35_production_deployment_checklist.md)

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- [`docs/DEVELOPMENT_GUIDE.md`](docs/DEVELOPMENT_GUIDE.md)
- [`docs/GITHUB_REPOSITORY_SETUP.md`](docs/GITHUB_REPOSITORY_SETUP.md)
- [`docs/ROADMAP.md`](docs/ROADMAP.md)
- [`docs/PROJECT_PHASE_HISTORY.md`](docs/PROJECT_PHASE_HISTORY.md)
- [`docs/GITHUB_READY_VALIDATION_REPORT.md`](docs/GITHUB_READY_VALIDATION_REPORT.md)
- [`CHANGELOG.md`](CHANGELOG.md)
- [`CONTRIBUTING.md`](CONTRIBUTING.md)

## Known pre-beta limitations

- TTS, STT, AI generation, real payments, subscriptions, corporate licensing, and receipt validation are placeholders.
- Runtime JSON persistence is suitable for local development and demos, not multi-instance production deployment.
- In-memory admin sessions and rate limiting must be moved to a shared store for horizontal scaling.
- Device-level FPS, memory, accessibility, and low-end Android testing are still required for the Phase 36 visuals.
- Store signing, Firebase configuration, privacy review, penetration testing, and restore drills are not complete.

## License

No open-source license is included. Treat this repository and its content as private and proprietary unless the owner explicitly chooses a license later.
