import 'package:career_chaos_academy/games/bug_hunt_room_game.dart';
import 'package:career_chaos_academy/games/developer_release_pipeline_engine.dart';
import 'package:career_chaos_academy/games/developer_release_pipeline_game.dart';
import 'package:career_chaos_academy/games/flame_mini_game_factory.dart';
import 'package:career_chaos_academy/models/developer_session_model.dart';
import 'package:career_chaos_academy/models/flame_mini_game_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/developer_session_director_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const director = DeveloperSessionDirectorService();

  group('Phase 36G session family rotation', () {
    test('first session is incident, then director alternates to pipeline', () {
      final first = director.nextPlan(
        history: const <FlameMiniGameResultModel>[],
        seed: 10,
      );
      final second = director.nextPlan(
        history: <FlameMiniGameResultModel>[_resultFor(first)],
        seed: 10,
      );
      final third = director.nextPlan(
        history: <FlameMiniGameResultModel>[
          _resultFor(second),
          _resultFor(first),
        ],
        seed: 10,
      );

      expect(first.family, DeveloperTaskFamily.liveIncident);
      expect(second.family, DeveloperTaskFamily.releasePipeline);
      expect(third.family, DeveloperTaskFamily.liveIncident);
    });

    test('factory routes explicit Developer plans to different game classes', () {
      const incidentPlan = DeveloperSessionPlan(
        family: DeveloperTaskFamily.liveIncident,
        modifier: DeveloperIncidentModifier.clientEscalation,
      );
      const pipelinePlan = DeveloperSessionPlan(
        family: DeveloperTaskFamily.releasePipeline,
        modifier: DeveloperIncidentModifier.hotfixWindow,
      );

      final incident = FlameMiniGameFactory.createDeveloperPlan(incidentPlan);
      final pipeline = FlameMiniGameFactory.createDeveloperPlan(pipelinePlan);

      expect(incident, isA<BugHuntRoomGame>());
      expect(pipeline, isA<DeveloperReleasePipelineGame>());
      expect(incident.definition.id, incidentPlan.runId);
      expect(pipeline.definition.id, pipelinePlan.runId);

      incident.disposeNotifiers();
      pipeline.disposeNotifiers();
    });

    test('support and profiling remain blocked until their mechanics exist', () {
      expect(DeveloperTaskFamily.supportEscalation.isPlayable, isFalse);
      expect(DeveloperTaskFamily.performanceProfiling.isPlayable, isFalse);
    });
  });

  group('Phase 36G Release Pipeline engine', () {
    test('healthy pipeline automatically advances to approval and ships', () {
      final engine = DeveloperReleasePipelineEngine(
        modifier: DeveloperIncidentModifier.noisyAlerts,
      );

      expect(engine.applyControl(DeveloperReleaseControl.start).accepted, isTrue);
      expect(
        engine.applyControl(DeveloperReleaseControl.boostRunners).accepted,
        isTrue,
      );

      _advanceUntil(
        engine,
        () => engine.statuses[DeveloperReleaseStage.production] ==
            DeveloperReleaseStageStatus.awaitingApproval,
      );

      expect(engine.passedStages, contains(DeveloperReleaseStage.staging));
      expect(engine.runnerCapacity, 2);
      expect(engine.runnerBoostUsed, isTrue);

      final approval =
          engine.applyControl(DeveloperReleaseControl.approveProduction);
      expect(approval.accepted, isTrue);
      expect(approval.disciplined, isTrue);

      _advanceUntil(engine, () => engine.isComplete);

      expect(engine.isComplete, isTrue);
      expect(engine.isFailed, isFalse);
      expect(engine.passedStages, hasLength(6));
      expect(engine.releaseHealth, 100);
    });

    test('flaky test gate really fails once and requires retry', () {
      final engine = DeveloperReleasePipelineEngine(
        modifier: DeveloperIncidentModifier.flakyTests,
      );

      engine.applyControl(DeveloperReleaseControl.start);
      engine.applyControl(DeveloperReleaseControl.boostRunners);

      _advanceUntil(
        engine,
        () => engine.failedStage == DeveloperReleaseStage.unitTests,
      );

      expect(engine.currentObjective, contains('Retry'));
      final retry = engine.applyControl(DeveloperReleaseControl.retryFailed);
      expect(retry.accepted, isTrue);
      expect(retry.disciplined, isTrue);

      _advanceUntil(
        engine,
        () => engine.statuses[DeveloperReleaseStage.production] ==
            DeveloperReleaseStageStatus.awaitingApproval,
      );
      engine.applyControl(DeveloperReleaseControl.approveProduction);
      _advanceUntil(engine, () => engine.isComplete);

      expect(engine.isComplete, isTrue);
      expect(engine.failedStage, isNull);
    });

    test('traffic spike forces first canary rollback before successful retry', () {
      final engine = DeveloperReleasePipelineEngine(
        modifier: DeveloperIncidentModifier.trafficSpike,
      );

      engine.applyControl(DeveloperReleaseControl.start);
      engine.applyControl(DeveloperReleaseControl.boostRunners);
      _advanceUntil(
        engine,
        () => engine.statuses[DeveloperReleaseStage.production] ==
            DeveloperReleaseStageStatus.awaitingApproval,
      );

      engine.applyControl(DeveloperReleaseControl.approveProduction);
      _advanceUntil(
        engine,
        () => engine.failedStage == DeveloperReleaseStage.production,
      );

      expect(engine.isComplete, isFalse);
      final rollback = engine.applyControl(DeveloperReleaseControl.rollback);
      expect(rollback.accepted, isTrue);
      expect(engine.rollbackCount, 1);
      expect(
        engine.statuses[DeveloperReleaseStage.production],
        DeveloperReleaseStageStatus.awaitingApproval,
      );

      engine.applyControl(DeveloperReleaseControl.approveProduction);
      _advanceUntil(engine, () => engine.isComplete);

      expect(engine.isComplete, isTrue);
      expect(engine.rollbackCount, 1);
      expect(engine.passedStages, contains(DeveloperReleaseStage.production));
    });

    test('premature production approval creates measurable chaos', () {
      final engine = DeveloperReleasePipelineEngine(
        modifier: DeveloperIncidentModifier.noisyAlerts,
      );
      final startingHealth = engine.releaseHealth;

      final outcome =
          engine.applyControl(DeveloperReleaseControl.approveProduction);

      expect(outcome.accepted, isFalse);
      expect(outcome.disciplined, isFalse);
      expect(engine.chaos, 2);
      expect(engine.releaseHealth, startingHealth - 5);
    });

    test('Release Pipeline retains established Developer reward contract', () {
      expect(
        DeveloperReleasePipelineGame.gameDefinition.successXp,
        BugHuntRoomGame.gameDefinition.successXp,
      );
      expect(
        DeveloperReleasePipelineGame.gameDefinition.failureXp,
        BugHuntRoomGame.gameDefinition.failureXp,
      );
      expect(
        DeveloperReleasePipelineGame.gameDefinition.successScoreImpact,
        BugHuntRoomGame.gameDefinition.successScoreImpact,
      );
      expect(
        DeveloperReleasePipelineGame.gameDefinition.failureScoreImpact,
        BugHuntRoomGame.gameDefinition.failureScoreImpact,
      );
    });
  });
}

void _advanceUntil(
  DeveloperReleasePipelineEngine engine,
  bool Function() condition, {
  int maxSeconds = 70,
}) {
  for (var second = 0; second < maxSeconds && !condition(); second += 1) {
    engine.update(1);
  }
  expect(condition(), isTrue, reason: 'Pipeline did not reach expected state.');
}

FlameMiniGameResultModel _resultFor(DeveloperSessionPlan plan) {
  return FlameMiniGameResultModel(
    gameId: plan.runId,
    kind: FlameMiniGameKind.bugHuntRoom,
    title: plan.title,
    completedAt: DateTime.utc(2026, 8, 24),
    isSuccess: true,
    correctCount: 6,
    wrongCount: 0,
    elapsedSeconds: 30,
    xpEarned: 120,
    scoreImpact: ScoreModel.zero,
    selectedTargetIds: const <String>{},
    message: 'completed',
  );
}
