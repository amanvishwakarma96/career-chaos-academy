# Career Chaos Academy — Phase 11 Regression Checklist

Use this checklist before marking a build ready for demo or release.

## Environment

- [ ] Run `flutter pub get` successfully.
- [ ] Run `flutter analyze` with no blocking issues.
- [ ] Run `flutter test` with all tests passing.
- [ ] Run `dotnet restore backend/CareerChaosAcademy.Api/CareerChaosAcademy.Api.csproj` successfully.
- [ ] Run `dotnet test backend/CareerChaosAcademy.Api.Tests/CareerChaosAcademy.Api.Tests.csproj` with all tests passing.
- [ ] Start the backend API and open Swagger.
- [ ] Start Flutter with and without `CAREER_CHAOS_API_BASE_URL`.

## Flutter App Regression

- [ ] Home screen loads all roles from local JSON when API is disabled.
- [ ] Home screen loads published roles from API when API is enabled.
- [ ] Role cards show icon, chapter count, and progress percent.
- [ ] Admin-only/unpublished API content does not appear in the Flutter app.
- [ ] Selecting a role opens the chapter list.
- [ ] Chapter 1 is unlocked by default.
- [ ] Locked chapters cannot be opened.
- [ ] Completing Chapter 1 unlocks Chapter 2.
- [ ] Progress percent updates after chapter completion.
- [ ] Scenario screen shows story/dialogue UI.
- [ ] Scenarios without mini-games show choices directly.
- [ ] Scenarios with mini-games show mini-game first and continue to choices after completion.
- [ ] Result screen updates score, XP, rank, and badges.
- [ ] Restarting the app preserves completed chapters, unlocked chapters, score, XP, rank, badges, and mini-game results.
- [ ] Reset progress clears local state and returns each role to only Chapter 1 unlocked.
- [ ] Dark mode toggle works and UI remains readable.
- [ ] Small mobile and tablet/wide layouts are usable.

## Mini-game Regression

- [ ] Developer `code_fix` accepts correct answer and improves score.
- [ ] QA `multiple_select` accepts exact correct set and rejects incomplete set.
- [ ] Back Office `data_cleanup` accepts correct cleanup selections.
- [ ] Doctor `match_pairs` validates correct pairs.
- [ ] Civil Engineer `arrange_order` validates correct order.
- [ ] Project Manager `decision_matrix` validates correct decisions.
- [ ] Wrong answers show funny consequence messages.
- [ ] Mini-game result is saved and not double-counted.

## Backend API Regression

- [ ] `GET /api/roles` returns published roles.
- [ ] `GET /api/roles/{roleId}/chapters` returns published chapters only.
- [ ] `GET /api/chapters/{chapterId}/scenario` returns choices and optional mini-game.
- [ ] `POST /api/users/{userId}/progress` saves valid progress.
- [ ] `GET /api/users/{userId}/progress` returns saved progress.
- [ ] Invalid progress payload returns 400.
- [ ] `POST /api/users/{userId}/scores` saves reasonable score impact.
- [ ] Oversized score impact returns 400.
- [ ] `GET /api/badges` returns badge catalog.

## Admin CMS Regression

- [ ] Admin can log in with configured credentials.
- [ ] Admin can create and update a role.
- [ ] Admin can create and update a chapter.
- [ ] Admin can save a scenario draft.
- [ ] Admin can add choices and outcomes.
- [ ] Admin can add supported mini-game config.
- [ ] Preview displays validation result.
- [ ] Invalid scenario cannot be published.
- [ ] Valid scenario can be published.
- [ ] Published content appears in Flutter API mode.
- [ ] Unpublished content disappears from Flutter API mode.
- [ ] AI-generated content can be submitted for review.
- [ ] Unsafe AI-generated content remains invalid and cannot be approved.
- [ ] Audit logs record create/update/publish/unpublish/review actions.

## Completion Sign-off

- [ ] No critical test failing.
- [ ] No blocking runtime crash found.
- [ ] Local fallback still works when API is offline.
- [ ] Manual regression is completed by tester name/date: ____________________
