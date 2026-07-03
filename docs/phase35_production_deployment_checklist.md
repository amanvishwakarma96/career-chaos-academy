# Phase 35 Production Deployment Checklist

## Authentication and token safety
- [x] Replace default `ADMIN_USERNAME`, `ADMIN_PASSWORD`, and `ADMIN_TOKEN_SECRET` before production.
- [x] Use short-lived admin tokens with expiry metadata.
- [x] Store Flutter access, refresh, and admin tokens through `SecureTokenStorageService` backed by platform secure storage.
- [x] Prefer HTTP-only, Secure, SameSite cookies for production admin web sessions.
- [x] Rotate admin secrets after team changes or suspected compromise.

## Backend API hardening
- [x] Enable API rate limiting for general and auth routes.
- [x] Enforce max JSON body size.
- [x] Reject invalid JSON and invalid write request bodies.
- [x] Apply permission-based RBAC to `/api/admin/*` endpoints.
- [x] Return security headers on API and static responses.
- [x] Keep public endpoints limited to non-sensitive app configuration, policy, and user-owned flows.

## Admin and content safety
- [x] Audit admin login success/failure and privileged actions.
- [x] Redact passwords, tokens, secrets, emails, phone numbers, OTPs, and address-like fields from audit details.
- [x] Require content moderation for AI/generated content and scenario packs before publish.
- [x] Block prompt-injection, credential exfiltration, evidence hiding, and unsafe professional advice patterns.
- [x] Keep AI/adaptive drafts as draft-only until approved.

## Privacy and retention
- [x] Provide privacy/data retention rules endpoint and documentation.
- [x] Keep admin analytics aggregate-only.
- [x] Preserve user analytics disable setting.
- [x] Store stack hashes, not raw stack traces, in prototype error events.
- [x] Define user export/delete/anonymization workflow before launch.

## Backup and restore
- [x] Provide development backup snapshot and restore API.
- [x] Maintain backup manifest and audit backup actions.
- [x] Production should use encrypted managed database/storage backups.
- [x] Perform restore drills before every major release.
- [x] Define RPO/RTO for corporate customers.

## Monitoring and operations
- [x] Keep Sentry/Firebase monitoring placeholders configurable from environment.
- [x] Add backend error report endpoint for app-side crash/error pipeline.
- [x] Capture request ID on errors for support triage.
- [x] Log slow requests for scale review.
- [x] Review rate-limit thresholds after load testing.

## Release gate
- [x] `npm run check` passes.
- [x] `npm run test:smoke` passes.
- [ ] Run `flutter analyze` locally.
- [ ] Run `flutter test` locally.
- [ ] Replace placeholder payment, TTS/STT, and AI integrations with production providers before charging users or enabling full voice/AI in production.
