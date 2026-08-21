import 'package:career_chaos_academy/games/bug_hunt_room_game.dart';
import 'package:career_chaos_academy/games/developer_incident_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 36E live Developer incident', () {
    test('Bug Hunt route now exposes six workflow tasks instead of quiz cards', () {
      final game = BugHuntRoomGame(seed: 101);

      expect(game.definition.title, 'Live Production Incident');
      expect(game.definition.targets, hasLength(6));
      expect(
        game.definition.targets.map((target) => target.id),
        containsAll(<String>{
          'inspect_logs',
          'reproduce_bug',
          'patch_state',
          'run_tests',
          'open_pr',
          'deploy_fix',
        }),
      );
    });

    test('disciplined workflow stabilizes production automatically', () {
      final engine = DeveloperIncidentEngine();

      for (final action in DeveloperIncidentAction.values) {
        final outcome = engine.resolve(action);
        expect(outcome.completed, isTrue);
        expect(outcome.disciplined, isTrue);
      }

      expect(engine.isComplete, isTrue);
      expect(engine.isFailed, isFalse);
      expect(engine.health, 100);
      expect(engine.chaos, 0);
      expect(engine.completedActions, hasLength(6));
    });

    test('unsafe deploy creates real chaos and does not complete the task', () {
      final engine = DeveloperIncidentEngine();

      final outcome = engine.resolve(DeveloperIncidentAction.deployFix);

      expect(outcome.completed, isFalse);
      expect(outcome.disciplined, isFalse);
      expect(engine.isComplete, isFalse);
      expect(engine.chaos, 7);
      expect(engine.health, 68);
      expect(
        engine.completedActions.contains(DeveloperIncidentAction.deployFix),
        isFalse,
      );
    });

    test('failed shortcut can be recovered by completing the real workflow', () {
      final engine = DeveloperIncidentEngine();

      engine.resolve(DeveloperIncidentAction.runTests);
      expect(engine.chaos, 3);
      expect(
        engine.completedActions.contains(DeveloperIncidentAction.runTests),
        isFalse,
      );

      engine.resolve(DeveloperIncidentAction.inspectLogs);
      engine.resolve(DeveloperIncidentAction.reproduceBug);
      engine.resolve(DeveloperIncidentAction.patchState);
      engine.resolve(DeveloperIncidentAction.runTests);
      engine.resolve(DeveloperIncidentAction.openPullRequest);
      engine.resolve(DeveloperIncidentAction.deployFix);

      expect(engine.isComplete, isTrue);
      expect(engine.health, 100);
      expect(engine.completedActions, hasLength(6));
      expect(engine.chaos, 3);
    });

    test('world keeps moving while player waits', () {
      final engine = DeveloperIncidentEngine();
      final startingHealth = engine.health;
      final startingFeedLength = engine.feed.length;

      for (var second = 0; second < 6; second += 1) {
        engine.tick();
      }

      expect(engine.elapsedSeconds, 6);
      expect(engine.health, lessThan(startingHealth));
      expect(engine.feed.length, greaterThan(startingFeedLength));
    });

    test('current task advances automatically after each completed action', () {
      final engine = DeveloperIncidentEngine();
      expect(engine.recommendedAction, DeveloperIncidentAction.inspectLogs);

      engine.resolve(DeveloperIncidentAction.inspectLogs);
      expect(engine.recommendedAction, DeveloperIncidentAction.reproduceBug);

      engine.resolve(DeveloperIncidentAction.reproduceBug);
      expect(engine.recommendedAction, DeveloperIncidentAction.patchState);
    });
  });
}
