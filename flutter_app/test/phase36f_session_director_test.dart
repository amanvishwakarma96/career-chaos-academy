import 'package:career_chaos_academy/games/bug_hunt_room_game.dart';
import 'package:career_chaos_academy/games/developer_incident_engine.dart';
import 'package:career_chaos_academy/models/developer_session_model.dart';
import 'package:career_chaos_academy/models/flame_mini_game_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/developer_session_director_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const director = DeveloperSessionDirectorService();

  group('Phase 36F Developer session director', () {
    test('does not repeat either of the two most recent family modifiers', () {
      const traffic = DeveloperSessionPlan(
        family: DeveloperTaskFamily.liveIncident,
        modifier: DeveloperIncidentModifier.trafficSpike,
      );
      const flaky = DeveloperSessionPlan(
        family: DeveloperTaskFamily.liveIncident,
        modifier: DeveloperIncidentModifier.flakyTests,
      );
      final history = <FlameMiniGameResultModel>[
        _resultFor(flaky),
        _resultFor(traffic),
      ];

      final next = director.nextPlanForFamily(
        family: DeveloperTaskFamily.liveIncident,
        history: history,
        seed: 41,
      );

      expect(next.family, DeveloperTaskFamily.liveIncident);
      expect(
        next.modifier,
        isNot(anyOf(
          DeveloperIncidentModifier.flakyTests,
          DeveloperIncidentModifier.trafficSpike,
        )),
      );
    });

    test('same seed and history produce the same family-scoped plan', () {
      const previous = DeveloperSessionPlan(
        family: DeveloperTaskFamily.liveIncident,
        modifier: DeveloperIncidentModifier.noisyAlerts,
      );
      final history = <FlameMiniGameResultModel>[_resultFor(previous)];

      final first = director.nextPlanForFamily(
        family: DeveloperTaskFamily.liveIncident,
        history: history,
        seed: 2026,
      );
      final second = director.nextPlanForFamily(
        family: DeveloperTaskFamily.liveIncident,
        history: history,
        seed: 2026,
      );

      expect(first.family, second.family);
      expect(first.modifier, second.modifier);
      expect(first.runId, second.runId);
    });

    test('run id round-trips through persisted Flame history format', () {
      const plan = DeveloperSessionPlan(
        family: DeveloperTaskFamily.liveIncident,
        modifier: DeveloperIncidentModifier.clientEscalation,
      );

      final parsed = director.planFromGameId(plan.runId);

      expect(parsed, isNotNull);
      expect(parsed!.family, plan.family);
      expect(parsed.modifier, plan.modifier);
    });

    test('legacy Bug Hunt history safely remains readable but has no modifier', () {
      expect(director.planFromGameId('flame_bug_hunt_room'), isNull);
    });

    test('first directed Developer session stays the Live Incident', () {
      for (var seed = 0; seed < 12; seed += 1) {
        final plan = director.nextPlan(
          history: const <FlameMiniGameResultModel>[],
          seed: seed,
        );
        expect(plan.family, DeveloperTaskFamily.liveIncident);
      }
    });

    test('unfinished Developer task families remain non-playable', () {
      expect(DeveloperTaskFamily.supportEscalation.isPlayable, isFalse);
      expect(DeveloperTaskFamily.performanceProfiling.isPlayable, isFalse);
    });
  });

  group('Phase 36F incident modifiers change actual mechanics', () {
    test('traffic spike drains health faster than the baseline incident', () {
      final baseline = DeveloperIncidentEngine();
      final traffic = DeveloperIncidentEngine(
        modifier: DeveloperIncidentModifier.trafficSpike,
      );
      final baselineStart = baseline.health;
      final trafficStart = traffic.health;

      for (var second = 0; second < 6; second += 1) {
        baseline.tick();
        traffic.tick();
      }

      expect(baselineStart - baseline.health, 2);
      expect(trafficStart - traffic.health, 6);
    });

    test('client escalation adds chaos automatically while player waits', () {
      final engine = DeveloperIncidentEngine(
        modifier: DeveloperIncidentModifier.clientEscalation,
      );

      for (var second = 0; second < 6; second += 1) {
        engine.tick();
      }

      expect(engine.chaos, 1);
      expect(
        engine.feed.any((line) => line.contains('ESCALATION')),
        isTrue,
      );
    });

    test('flaky test modifier creates a real retry task instead of fake feedback', () {
      final engine = DeveloperIncidentEngine(
        modifier: DeveloperIncidentModifier.flakyTests,
      );
      engine.resolve(DeveloperIncidentAction.inspectLogs);
      engine.resolve(DeveloperIncidentAction.reproduceBug);
      engine.resolve(DeveloperIncidentAction.patchState);

      final firstTest = engine.resolve(DeveloperIncidentAction.runTests);
      expect(firstTest.disciplined, isTrue);
      expect(firstTest.completed, isFalse);
      expect(engine.recommendedAction, DeveloperIncidentAction.runTests);
      expect(engine.currentTask, contains('retry'));

      final retry = engine.resolve(DeveloperIncidentAction.runTests);
      expect(retry.completed, isTrue);
      expect(
        engine.completedActions.contains(DeveloperIncidentAction.runTests),
        isTrue,
      );
    });

    test('Bug Hunt definition records the session plan in the result game id', () {
      const plan = DeveloperSessionPlan(
        family: DeveloperTaskFamily.liveIncident,
        modifier: DeveloperIncidentModifier.hotfixWindow,
      );
      final game = BugHuntRoomGame(sessionPlan: plan);

      expect(game.definition.id, plan.runId);
      expect(game.definition.subtitle, contains(plan.modifier.label));
      expect(game.incident.processingMultiplier, lessThan(1));

      game.disposeNotifiers();
    });
  });
}

FlameMiniGameResultModel _resultFor(DeveloperSessionPlan plan) {
  return FlameMiniGameResultModel(
    gameId: plan.runId,
    kind: FlameMiniGameKind.bugHuntRoom,
    title: plan.title,
    completedAt: DateTime.utc(2026, 8, 21),
    isSuccess: true,
    correctCount: 6,
    wrongCount: 0,
    elapsedSeconds: 30,
    xpEarned: 120,
    scoreImpact: ScoreModel.zero,
    selectedTargetIds: const <String>{},
    message: 'contained',
  );
}
