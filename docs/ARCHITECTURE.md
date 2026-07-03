# Career Chaos Academy Architecture

## Overview

Career Chaos Academy uses a hybrid architecture:

- **Flutter** owns application navigation, dashboards, forms, accessibility, settings, and local-first state.
- **Flame** owns real-time mini-games, particle effects, cinematic atmosphere, direct canvas interaction, and game-loop-driven motion.
- **Node.js** serves content, progress APIs, admin tools, feature configuration, enterprise workflows, analytics, security controls, and prototype persistence.
- **JSON assets** provide versioned role scenarios, skill trees, activities, mentors, interview banks, assessments, voice profiles, product metadata, and feature flags.

## Flutter application

```text
flutter_app/lib/
├── app/                 # App root, routes and theme
├── content_generation/  # Safe scenario-generation tooling
├── core/                # Registries and shared infrastructure
├── data/                # Bundled content lookup and repositories
├── games/               # Flame game classes and components
├── models/              # Domain and persistence models
├── screens/             # Flutter application screens
├── services/            # API, progress, analytics, audio, security, config
└── widgets/              # Reusable Flutter widgets
```

### Client principles

- Local-first content and progress fallback.
- Feature-flagged experimental modules.
- Optional backend connectivity through `CAREER_CHAOS_API_BASE_URL`.
- Secure token storage for sensitive tokens.
- Reduced-motion and visual-quality preferences.
- Subtitle-first character conversation.

## Flame integration

Flame is used selectively rather than replacing the full Flutter application.

```text
Flutter screen
  ├── GameWidget / FlameGame
  │     ├── components
  │     ├── particles and effects
  │     ├── game loop and timers
  │     └── direct pointer input
  └── Flutter overlays
        ├── HUD
        ├── pause/settings
        ├── dialogue/decision UI
        └── debrief/navigation
```

Phase 36 currently provides a vertical slice for Developer Chapter 1 and Bug Hunt Room. The same component system should be expanded incrementally after visual and performance approval.

## Backend application

```text
backend_nodejs/
├── data/
│   ├── config/          # Feature and content configuration
│   ├── scenarios/       # Role scenario source data
│   ├── runtime/         # Mutable local data; ignored by Git
│   └── ...              # Activities, skills, interviews, assessments, etc.
├── public/admin/        # Static admin panel
└── src/
    ├── config.js        # Environment configuration
    ├── dataStore.js     # Prototype JSON persistence and domain logic
    ├── security.js      # RBAC, validation, rate limiting, redaction
    ├── server.js        # HTTP routing and static hosting
    ├── smoke-test.js    # End-to-end backend smoke validation
    └── validation.js    # Scenario and content validation
```

### Backend boundaries

The current backend is intentionally dependency-light and suitable for demos and local development. For production scaling, separate these responsibilities:

1. API gateway / edge rate limiting.
2. Identity and session service.
3. Content and scenario service.
4. Progress, assessment, and certificate service.
5. Organization and licensing service.
6. Analytics event ingestion and warehouse.
7. AI/voice provider integration service.
8. Queue workers for certificates, reports, and moderation jobs.

## Data flow

```text
Bundled JSON ───────┐
                    ├── Flutter repositories/services ── UI / Flame gameplay
Node API ───────────┘               │
                                    ├── local progress
                                    └── backend sync when available

Admin panel ── Node admin APIs ── content/config/runtime prototype data
```

## Security model

- Admin permissions are role-based.
- Privileged actions produce privacy-safe audit events.
- Request body size and selected payload shapes are validated.
- General and login routes have prototype rate limiting.
- Prompt-abuse and content moderation checks gate generated content.
- Flutter uses platform secure storage for tokens.
- Runtime files are excluded from source control.

Production must replace in-memory sessions/rate limits and JSON runtime persistence with managed shared services.
