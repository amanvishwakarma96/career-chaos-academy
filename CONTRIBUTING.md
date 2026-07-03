# Contributing to Career Chaos Academy

Career Chaos Academy is currently maintained as a private project. Contributors should use small, reviewable branches and preserve backward compatibility with existing scenario and progress data.

## Branch naming

```text
feature/<short-description>
fix/<short-description>
security/<short-description>
content/<role-or-pack>
docs/<short-description>
```

Examples:

```text
feature/phase36-qa-visual-polish
fix/bug-hunt-timer-reset
content/developer-chapter-2
```

## Local checks before opening a pull request

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

Or run:

```bash
./scripts/validate_all.sh
```

## Coding expectations

- Keep Flutter UI, data models, services, and Flame components separated.
- Preserve local-first fallback behavior when backend calls fail.
- Do not bypass feature flags for incomplete or provider-dependent features.
- Keep scenario JSON backward compatible unless a documented migration exists.
- Add or update tests whenever gameplay, scoring, security, or persistence logic changes.
- Do not commit generated runtime data, credentials, signing files, or provider secrets.
- Respect reduced-motion and visual-quality settings for animation work.
- Human review is mandatory before publishing AI-generated scenarios or professional advice content.

## Commit messages

Use clear, imperative messages:

```text
feat: add cinematic developer chapter transition
fix: prevent duplicate team decision submission
test: cover certificate pass gate
docs: update local setup instructions
security: redact authorization metadata from audit logs
```

## Pull request checklist

- [ ] Scope is focused and described clearly.
- [ ] Backend checks pass when backend code changed.
- [ ] Flutter analyze and tests pass when Flutter code changed.
- [ ] New assets are optimized and listed in `pubspec.yaml` when needed.
- [ ] Feature flags and fallback behavior are considered.
- [ ] No secrets or runtime user data are included.
- [ ] Documentation and validation reports are updated.
- [ ] Screenshots or recordings are included for visual changes.
