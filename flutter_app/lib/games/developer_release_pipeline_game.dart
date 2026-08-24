import 'dart:async';
import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/developer_session_model.dart';
import '../models/flame_mini_game_model.dart';
import '../models/score_model.dart';
import '../services/animation_service.dart';
import '../services/audio_service.dart';
import '../services/developer_session_director_service.dart';
import '../services/progress_service.dart';
import 'base_mini_game.dart';
import 'developer_release_pipeline_engine.dart';

class DeveloperReleasePipelineGame extends BaseMiniGame {
  factory DeveloperReleasePipelineGame({
    int? seed,
    DeveloperSessionPlan? sessionPlan,
  }) {
    final plan = sessionPlan ??
        DeveloperSessionDirectorService.instance.nextPlanForFamily(
          family: DeveloperTaskFamily.releasePipeline,
          history: ProgressService.instance.flameMiniGameHistory.value,
          seed: seed,
        );
    if (plan.family != DeveloperTaskFamily.releasePipeline) {
      throw ArgumentError.value(
        plan.family,
        'sessionPlan.family',
        'Release Pipeline requires the releasePipeline task family.',
      );
    }
    return DeveloperReleasePipelineGame._(plan);
  }

  DeveloperReleasePipelineGame._(this.sessionPlan)
      : engine = DeveloperReleasePipelineEngine(modifier: sessionPlan.modifier),
        super(definition: _definitionFor(sessionPlan));

  static const FlameMiniGameDefinitionModel gameDefinition =
      FlameMiniGameDefinitionModel(
    id: 'flame_bug_hunt_room|release_pipeline|hotfix_window',
    kind: FlameMiniGameKind.bugHuntRoom,
    title: 'Release Pipeline',
    subtitle:
        'Operate a live CI/CD pipeline: unblock jobs, manage capacity, approve gates and recover failed rollout attempts.',
    instructions:
        'Start the pipeline and let eligible jobs process automatically. Add runner capacity when useful, retry real failures, approve production only after green gates, and roll back an unhealthy canary.',
    timeLimitSeconds: 75,
    successThreshold: 6,
    successScoreImpact: ScoreModel(
      skill: 5,
      discipline: 3,
      communication: 1,
      ethics: 1,
      chaos: -2,
    ),
    failureScoreImpact: ScoreModel(
      skill: 1,
      discipline: -1,
      communication: 0,
      ethics: 0,
      chaos: 3,
    ),
    successXp: 120,
    failureXp: 35,
    successMessage:
        'Release completed. Every required gate passed and production rollout is healthy.',
    failureMessage:
        'Release run ended before production became healthy. Review blocked gates, retries and rollback timing.',
    targets: <FlameMiniGameTargetModel>[
      FlameMiniGameTargetModel(
        id: 'pipeline_source',
        label: 'Source',
        hint: 'Checkout release source.',
        isCorrect: true,
        feedback: 'Source ready.',
      ),
      FlameMiniGameTargetModel(
        id: 'pipeline_build',
        label: 'Build',
        hint: 'Compile the release candidate.',
        isCorrect: true,
        feedback: 'Build ready.',
      ),
      FlameMiniGameTargetModel(
        id: 'pipeline_tests',
        label: 'Tests',
        hint: 'Run automated regression tests.',
        isCorrect: true,
        feedback: 'Tests ready.',
      ),
      FlameMiniGameTargetModel(
        id: 'pipeline_security',
        label: 'Security',
        hint: 'Run security gate.',
        isCorrect: true,
        feedback: 'Security gate ready.',
      ),
      FlameMiniGameTargetModel(
        id: 'pipeline_staging',
        label: 'Staging',
        hint: 'Deploy release candidate to staging.',
        isCorrect: true,
        feedback: 'Staging ready.',
      ),
      FlameMiniGameTargetModel(
        id: 'pipeline_production',
        label: 'Production',
        hint: 'Roll out the verified release.',
        isCorrect: true,
        feedback: 'Production ready.',
      ),
    ],
  );

  static FlameMiniGameDefinitionModel _definitionFor(
    DeveloperSessionPlan plan,
  ) {
    return FlameMiniGameDefinitionModel(
      id: plan.runId,
      kind: gameDefinition.kind,
      title: gameDefinition.title,
      subtitle: '${plan.modifier.label} • ${_pipelineBriefing(plan.modifier)}',
      instructions: gameDefinition.instructions,
      timeLimitSeconds: gameDefinition.timeLimitSeconds,
      successThreshold: gameDefinition.successThreshold,
      successScoreImpact: gameDefinition.successScoreImpact,
      failureScoreImpact: gameDefinition.failureScoreImpact,
      successXp: gameDefinition.successXp,
      failureXp: gameDefinition.failureXp,
      successMessage: gameDefinition.successMessage,
      failureMessage: gameDefinition.failureMessage,
      targets: gameDefinition.targets,
    );
  }

  static String _pipelineBriefing(DeveloperIncidentModifier modifier) {
    switch (modifier) {
      case DeveloperIncidentModifier.trafficSpike:
        return 'A traffic surge will stress the first production canary. Expect a rollback decision.';
      case DeveloperIncidentModifier.flakyTests:
        return 'The first test gate can fail transiently. Retry evidence matters more than guessing.';
      case DeveloperIncidentModifier.clientEscalation:
        return 'Stakeholder pressure adds chaos while the release stays open.';
      case DeveloperIncidentModifier.noisyAlerts:
        return 'Monitoring noise will compete with real pipeline signals.';
      case DeveloperIncidentModifier.hotfixWindow:
        return 'Jobs run faster, but the release window steadily consumes health.';
    }
  }

  final DeveloperSessionPlan sessionPlan;
  final DeveloperReleasePipelineEngine engine;

  String? _lastFeedLine;
  DeveloperReleaseStage? _lastFailedStage;
  int _lastPassedCount = 0;
  double _visualTime = 0;
  double _dangerFlash = 0;
  bool _completionCelebrated = false;

  bool get _reducedMotion => AnimationService.instance.isReducedMotion;

  @override
  String progressSummary(Set<String> selected) {
    return '${engine.passedStages.length}/6 gates green • '
        '${engine.runningCount} running • '
        'Runners ${engine.runningCount}/${engine.runnerCapacity} • '
        'Health ${engine.releaseHealth}%';
  }

  @override
  bool get allowClearSelection => false;

  @override
  String get submitActionLabel => 'Finish Release Run';

  @override
  String get retryActionLabel => 'Next Developer Challenge';

  @override
  String resultDialogTitle(FlameMiniGameResultModel result) {
    return result.isSuccess ? 'Release shipped!' : 'Release report generated';
  }

  @override
  List<String> resultSummaryLabels(FlameMiniGameResultModel result) {
    return <String>[
      'XP +${result.xpEarned}',
      'Gates ${engine.passedStages.length}/6',
      'Chaos ${engine.chaos}',
      'Rollbacks ${engine.rollbackCount}',
      '${result.elapsedSeconds}s',
    ];
  }

  @override
  void update(double dt) {
    super.update(dt);
    _visualTime += dt;
    _dangerFlash = math.max(0, _dangerFlash - dt);

    if (isFinished) {
      return;
    }

    engine.update(dt);
    _syncPassedStages();
    _surfaceEngineChanges();
  }

  void _syncPassedStages() {
    selectedTargetIds.value = Set<String>.unmodifiable(
      engine.passedStages.map((stage) => stage.id),
    );
  }

  void _surfaceEngineChanges() {
    final passedCount = engine.passedStages.length;
    if (passedCount > _lastPassedCount) {
      _lastPassedCount = passedCount;
      comboCount.value = passedCount;
      unawaited(AudioService.instance.playSoundEffect('notification_ping'));
      HapticFeedback.lightImpact();
    }

    final failedStage = engine.failedStage;
    if (failedStage != null && failedStage != _lastFailedStage) {
      _lastFailedStage = failedStage;
      _dangerFlash = _reducedMotion ? 0 : 0.32;
      comboCount.value = 0;
      unawaited(AudioService.instance.playSoundEffect('alert_buzz'));
      HapticFeedback.heavyImpact();
    } else if (failedStage == null) {
      _lastFailedStage = null;
    }

    if (engine.feed.isNotEmpty) {
      final latest = engine.feed.last;
      if (latest != _lastFeedLine) {
        _lastFeedLine = latest;
        feedbackMessage.value = latest;
      }
    }

    if (engine.isComplete && !_completionCelebrated) {
      _completionCelebrated = true;
      feedbackMessage.value =
          'Release healthy. All six gates are green and production reached 100%.';
      comboCount.value = 6;
      unawaited(AudioService.instance.playSoundEffect('notification_ping'));
      HapticFeedback.mediumImpact();
    }

    if (engine.isFailed) {
      feedbackMessage.value = engine.currentObjective;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isFinished || engine.isComplete || engine.isFailed) {
      return;
    }
    final tap = Offset(event.localPosition.x, event.localPosition.y);
    final controls = DeveloperReleaseControl.values;
    for (var index = 0; index < controls.length; index += 1) {
      if (!_controlRect(index).inflate(5).contains(tap)) {
        continue;
      }
      final outcome = engine.applyControl(controls[index]);
      feedbackMessage.value = outcome.message;
      if (outcome.accepted && outcome.disciplined) {
        unawaited(AudioService.instance.playSoundEffect('choice_select'));
        HapticFeedback.selectionClick();
      } else if (!outcome.disciplined) {
        _dangerFlash = _reducedMotion ? 0 : 0.28;
        unawaited(AudioService.instance.playSoundEffect('comedy_bonk'));
        HapticFeedback.heavyImpact();
      }
      _syncPassedStages();
      return;
    }
  }

  @override
  void clearSelection() {
    feedbackMessage.value =
        'Passed pipeline gates cannot be cleared. ${engine.currentObjective}';
  }

  // This game uses a pipeline renderer rather than BaseMiniGame target cards.
  // ignore: must_call_super
  @override
  void render(Canvas canvas) {
    final bounds = Offset.zero & Size(size.x, size.y);
    _drawBackground(canvas, bounds);
    _drawHeader(canvas);
    _drawObjective(canvas);
    _drawPipeline(canvas);
    _drawFeed(canvas);
    _drawControls(canvas);
    _drawDanger(canvas, bounds);
  }

  void _drawBackground(Canvas canvas, Rect bounds) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF071018),
            Color(0xFF0A1826),
            Color(0xFF05070B),
          ],
        ).createShader(bounds),
    );

    final scanPaint = Paint()
      ..color = const Color(0xFF7AF7D0).withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const spacing = 28.0;
    final shift = _reducedMotion ? 0.0 : (_visualTime * 12) % spacing;
    for (double y = -spacing + shift; y < size.y; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), scanPaint);
    }
  }

  void _drawHeader(Canvas canvas) {
    final healthColor = engine.releaseHealth >= 70
        ? const Color(0xFF58F0C2)
        : engine.releaseHealth >= 40
            ? const Color(0xFFFFC857)
            : const Color(0xFFFF6077);
    _drawText(
      canvas,
      'CI/CD • ${sessionPlan.modifier.label.toUpperCase()}',
      const Offset(16, 12),
      fontSize: 9.5,
      color: const Color(0xFF7AF7D0),
      fontWeight: FontWeight.w900,
      maxWidth: math.max(120, size.x - 150),
    );
    _drawText(
      canvas,
      'Release health ${engine.releaseHealth}%',
      const Offset(16, 31),
      fontSize: 14,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      maxWidth: size.x * 0.60,
    );

    final bar = Rect.fromLTWH(16, 53, math.max(100, size.x - 154), 7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: 0.09),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          bar.left,
          bar.top,
          bar.width * (engine.releaseHealth / 100),
          bar.height,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = healthColor,
    );

    final stats = Rect.fromLTWH(math.max(16, size.x - 130), 16, 114, 48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stats, const Radius.circular(13)),
      Paint()..color = const Color(0xFF0B111B).withValues(alpha: 0.92),
    );
    _drawText(
      canvas,
      'RUNNERS ${engine.runningCount}/${engine.runnerCapacity}',
      Offset(stats.left + 8, stats.top + 8),
      fontSize: 8,
      color: const Color(0xFF70D6FF),
      fontWeight: FontWeight.w900,
      maxWidth: stats.width - 16,
      textAlign: TextAlign.center,
    );
    _drawText(
      canvas,
      'CHAOS ${engine.chaos} • ${remainingSeconds.value}s',
      Offset(stats.left + 8, stats.top + 26),
      fontSize: 7.5,
      color: Colors.white70,
      fontWeight: FontWeight.w800,
      maxWidth: stats.width - 16,
      textAlign: TextAlign.center,
    );
  }

  void _drawObjective(Canvas canvas) {
    final rect = Rect.fromLTWH(16, 72, math.max(120, size.x - 32), 44);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()..color = const Color(0xFF0B1420).withValues(alpha: 0.92),
    );
    _drawText(
      canvas,
      'LIVE OBJECTIVE',
      Offset(rect.left + 10, rect.top + 7),
      fontSize: 7.5,
      color: const Color(0xFFFFC857),
      fontWeight: FontWeight.w900,
      maxWidth: rect.width - 20,
    );
    _drawText(
      canvas,
      engine.currentObjective,
      Offset(rect.left + 10, rect.top + 20),
      fontSize: 8.5,
      color: Colors.white,
      fontWeight: FontWeight.w700,
      maxWidth: rect.width - 20,
      maxLines: 2,
    );
  }

  void _drawPipeline(Canvas canvas) {
    _drawConnector(
      canvas,
      _stageRect(DeveloperReleaseStage.source).bottomCenter,
      _stageRect(DeveloperReleaseStage.build).topCenter,
    );
    _drawConnector(
      canvas,
      _stageRect(DeveloperReleaseStage.build).bottomCenter,
      _stageRect(DeveloperReleaseStage.unitTests).topCenter,
    );
    _drawConnector(
      canvas,
      _stageRect(DeveloperReleaseStage.build).bottomCenter,
      _stageRect(DeveloperReleaseStage.securityScan).topCenter,
    );
    _drawConnector(
      canvas,
      _stageRect(DeveloperReleaseStage.unitTests).bottomCenter,
      _stageRect(DeveloperReleaseStage.staging).topCenter,
    );
    _drawConnector(
      canvas,
      _stageRect(DeveloperReleaseStage.securityScan).bottomCenter,
      _stageRect(DeveloperReleaseStage.staging).topCenter,
    );
    _drawConnector(
      canvas,
      _stageRect(DeveloperReleaseStage.staging).bottomCenter,
      _stageRect(DeveloperReleaseStage.production).topCenter,
    );

    for (final stage in DeveloperReleaseStage.values) {
      _drawStage(canvas, stage);
    }
  }

  Rect _stageRect(DeveloperReleaseStage stage) {
    final center = size.x / 2;
    final halfGap = math.min(74.0, size.x * 0.22);
    const width = 112.0;
    const height = 38.0;
    switch (stage) {
      case DeveloperReleaseStage.source:
        return Rect.fromCenter(
          center: Offset(center, 140),
          width: width,
          height: height,
        );
      case DeveloperReleaseStage.build:
        return Rect.fromCenter(
          center: Offset(center, 189),
          width: width,
          height: height,
        );
      case DeveloperReleaseStage.unitTests:
        return Rect.fromCenter(
          center: Offset(center - halfGap, 238),
          width: width,
          height: height,
        );
      case DeveloperReleaseStage.securityScan:
        return Rect.fromCenter(
          center: Offset(center + halfGap, 238),
          width: width,
          height: height,
        );
      case DeveloperReleaseStage.staging:
        return Rect.fromCenter(
          center: Offset(center, 287),
          width: width,
          height: height,
        );
      case DeveloperReleaseStage.production:
        return Rect.fromCenter(
          center: Offset(center, 336),
          width: width,
          height: height,
        );
    }
  }

  void _drawConnector(Canvas canvas, Offset from, Offset to) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = const Color(0xFF70D6FF).withValues(alpha: 0.24)
        ..strokeWidth = 1.5,
    );
  }

  void _drawStage(Canvas canvas, DeveloperReleaseStage stage) {
    final rect = _stageRect(stage);
    final status = engine.statuses[stage] ?? DeveloperReleaseStageStatus.queued;
    final progress = engine.progress[stage] ?? 0;
    final color = _statusColor(status);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: 0.20),
            const Color(0xFF090D14).withValues(alpha: 0.98),
          ],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = status == DeveloperReleaseStageStatus.running ? 1.8 : 1.0
        ..color = color.withValues(alpha: 0.78),
    );

    _drawText(
      canvas,
      stage.label,
      Offset(rect.left + 8, rect.top + 7),
      fontSize: 8.5,
      color: color,
      fontWeight: FontWeight.w900,
      maxWidth: rect.width - 16,
    );
    _drawText(
      canvas,
      _statusLabel(status),
      Offset(rect.left + 8, rect.top + 21),
      fontSize: 6.8,
      color: Colors.white70,
      fontWeight: FontWeight.w800,
      maxWidth: rect.width - 16,
    );

    if (status == DeveloperReleaseStageStatus.running) {
      final progressRect = Rect.fromLTWH(
        rect.left + 7,
        rect.bottom - 5,
        (rect.width - 14) * progress,
        2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(progressRect, const Radius.circular(2)),
        Paint()..color = color,
      );
    }
  }

  String _statusLabel(DeveloperReleaseStageStatus status) {
    switch (status) {
      case DeveloperReleaseStageStatus.queued:
        return 'QUEUED';
      case DeveloperReleaseStageStatus.running:
        return 'RUNNING';
      case DeveloperReleaseStageStatus.passed:
        return 'GREEN';
      case DeveloperReleaseStageStatus.failed:
        return 'FAILED';
      case DeveloperReleaseStageStatus.awaitingApproval:
        return 'AWAITING APPROVAL';
    }
  }

  Color _statusColor(DeveloperReleaseStageStatus status) {
    switch (status) {
      case DeveloperReleaseStageStatus.queued:
        return const Color(0xFF76839B);
      case DeveloperReleaseStageStatus.running:
        return const Color(0xFF70D6FF);
      case DeveloperReleaseStageStatus.passed:
        return const Color(0xFF58F0C2);
      case DeveloperReleaseStageStatus.failed:
        return const Color(0xFFFF6077);
      case DeveloperReleaseStageStatus.awaitingApproval:
        return const Color(0xFFFFC857);
    }
  }

  void _drawFeed(Canvas canvas) {
    final rect = Rect.fromLTWH(16, 362, math.max(120, size.x - 32), 54);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );
    final visible = engine.feed.reversed.take(2).toList().reversed.toList();
    var y = rect.top + 8;
    for (final line in visible) {
      _drawText(
        canvas,
        '› $line',
        Offset(rect.left + 9, y),
        fontSize: 6.9,
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        maxWidth: rect.width - 18,
        maxLines: 1,
      );
      y += 19;
    }
  }

  void _drawControls(Canvas canvas) {
    final controls = DeveloperReleaseControl.values;
    for (var index = 0; index < controls.length; index += 1) {
      final control = controls[index];
      final rect = _controlRect(index);
      final accent = _controlAccent(control);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(11)),
        Paint()..color = accent.withValues(alpha: 0.13),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(11)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = accent.withValues(alpha: 0.55),
      );
      _drawText(
        canvas,
        control.label,
        Offset(rect.left + 5, rect.top + 11),
        fontSize: 7.2,
        color: accent,
        fontWeight: FontWeight.w900,
        maxWidth: rect.width - 10,
        textAlign: TextAlign.center,
      );
    }
  }

  Rect _controlRect(int index) {
    const gap = 6.0;
    const horizontalPadding = 16.0;
    final usableWidth = math.max(270.0, size.x) - horizontalPadding * 2;
    final width = (usableWidth - gap * 4) / 5;
    final y = math.max(423.0, size.y - 49);
    return Rect.fromLTWH(
      horizontalPadding + index * (width + gap),
      y,
      width,
      34,
    );
  }

  Color _controlAccent(DeveloperReleaseControl control) {
    switch (control) {
      case DeveloperReleaseControl.start:
        return engine.started
            ? const Color(0xFF76839B)
            : const Color(0xFF58F0C2);
      case DeveloperReleaseControl.boostRunners:
        return engine.runnerBoostUsed
            ? const Color(0xFF76839B)
            : const Color(0xFF70D6FF);
      case DeveloperReleaseControl.retryFailed:
        return engine.failedStage == null
            ? const Color(0xFF76839B)
            : const Color(0xFFFFC857);
      case DeveloperReleaseControl.approveProduction:
        return engine.statuses[DeveloperReleaseStage.production] ==
                DeveloperReleaseStageStatus.awaitingApproval
            ? const Color(0xFF58F0C2)
            : const Color(0xFF76839B);
      case DeveloperReleaseControl.rollback:
        final production = engine.statuses[DeveloperReleaseStage.production];
        return production == DeveloperReleaseStageStatus.failed ||
                production == DeveloperReleaseStageStatus.running
            ? const Color(0xFFFF6077)
            : const Color(0xFF76839B);
    }
  }

  void _drawDanger(Canvas canvas, Rect bounds) {
    if (engine.releaseHealth >= 40 &&
        engine.failedStage == null &&
        _dangerFlash <= 0) {
      return;
    }
    final pulse = _reducedMotion ? 0.4 : (math.sin(_visualTime * 9) + 1) / 2;
    canvas.drawRect(
      bounds,
      Paint()
        ..color = const Color(0xFFFF4059).withValues(
          alpha: 0.02 + pulse * 0.05,
        ),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w500,
    double? maxWidth,
    int maxLines = 2,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.05,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? math.max(80.0, size.x - 36));
    painter.paint(canvas, offset);
  }
}
