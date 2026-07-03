# Career Chaos Academy Node.js Backend

This folder contains the dependency-light Node.js API and static web admin panel for Career Chaos Academy.

## Responsibilities

- Published role, chapter, scenario, character, activity, skill-tree, interview, assessment, and product metadata APIs.
- Local-first progress and score synchronization.
- Scenario marketplace and moderation workflows.
- Team simulation sessions and debrief data.
- Interview reports, assessment sessions, certificates, and verification.
- Organization, batch, assignment, progress, and export prototypes.
- Voice/chat, analytics, monetization, and provider placeholders.
- Admin RBAC, audit logs, request validation, prompt-abuse checks, rate limiting, backups, and error-event records.
- Static admin panel at `/admin/`.

## Requirements

- Node.js 18 or newer
- Node.js 20 LTS recommended

The current implementation uses Node.js built-in modules and has no external npm runtime dependencies.

## Configuration

Review and copy the development template:

```bash
cp .env.example .env
set -a
source .env
set +a
```

The server reads `process.env` directly. On Windows, load values using PowerShell, your IDE, Docker, or a process manager.

Example for macOS/Linux:

```bash
export ADMIN_USERNAME=admin
export ADMIN_PASSWORD='replace-this-password'
export ADMIN_TOKEN_SECRET='replace-with-a-long-random-secret'
export PORT=5085
npm start
```

Never deploy using the defaults from `.env.example`.

## Commands

```bash
npm ci
npm run check
npm run test:smoke
npm start
```

Development watch mode:

```bash
npm run dev
```

## URLs

```text
Health: http://localhost:5085/api/health
Admin:  http://localhost:5085/admin/
```

## Project layout

```text
backend_nodejs/
├── data/
│   ├── config/          # Feature/content configuration
│   ├── scenarios/       # Role scenario source data
│   ├── runtime/         # Generated local mutable data; ignored by Git
│   └── ...              # Activities, skills, assessments, voice, etc.
├── public/admin/        # Static admin UI
└── src/
    ├── config.js
    ├── dataStore.js
    ├── security.js
    ├── server.js
    ├── smoke-test.js
    └── validation.js
```

## API groups

The backend exposes APIs under these broad groups:

```text
/api/health
/api/roles, /api/chapters, /api/characters
/api/users/*/progress, /api/users/*/scores
/api/activities, /api/skill-trees, /api/professional
/api/scenario-packs
/api/team-sessions
/api/interview
/api/assessments, /api/certificates
/api/organizations
/api/voice
/api/analytics
/api/monetization
/api/config, /api/content, /api/assets, /api/i18n
/api/admin/*
```

Use the source route definitions and smoke tests as the executable API reference while the API is still evolving.

## Admin authentication

Admin login returns a prototype token. Privileged routes accept:

```text
Authorization: Bearer <admin-token>
```

or the compatibility header:

```text
X-Admin-Token: <admin-token>
```

Admin sessions are currently stored in memory and are not suitable for multi-instance production deployment.

## Runtime data

Generated mutable data is stored under:

```text
data/runtime/
```

It is intentionally ignored by Git. It may contain user progress, sessions, reports, analytics events, audit logs, generated content, certificates, or conversations.

For production:

- Replace JSON persistence with a managed database.
- Replace in-memory admin sessions and rate limiting with Redis or another shared store.
- Use encrypted managed backups and tested restore procedures.
- Add queues for long-running certificate, report, moderation, and AI tasks.

## Security notes

Phase 35 provides production-readiness architecture, including:

- Request body limits and selected request-shape validation.
- Permission-based admin RBAC.
- Privacy-safe audit metadata redaction.
- Prompt-abuse inspection and content moderation.
- Prototype request rate limiting.
- Security headers and request IDs.
- Crash/error event ingestion with redacted metadata.
- Backup/restore development endpoints.

Before production, configure restrictive CORS, TLS, managed identity/session storage, centralized secrets, dependency/security scanning, penetration testing, and privacy workflows.

## Flutter connection

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
