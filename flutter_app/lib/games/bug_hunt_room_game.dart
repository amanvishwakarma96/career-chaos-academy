import 'dart:async';
import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/flame_mini_game_model.dart';
import '../models/score_model.dart';
import '../services/animation_service.dart';
import '../services/audio_service.dart';
import 'base_mini_game.dart';
import 'developer_incident_engine.dart';

class BugHuntRoomGame extends BaseMiniGame {
  BugHuntRoomGame({int? seed}) : super(definition: gameDefinition);

  static const FlameMiniGameDefinitionModel gameDefinition =
      FlameMiniGameDefinitionModel(
    id: 'flame_bug_hunt_room',
    kind: FlameMiniGameKind.bugHuntRoom,
    title: 'Live Production Incident',
    subtitle:
        'Work the incident. Production changes while you investigate, test and release.',
    instructions:
        'This is not a quiz. Use the workstation tools, watch production health, and stabilize the login incident. Actions process automatically and unlock the next task.',
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
        'Incident contained. You used evidence, verification and review to restore production.',
    failureMessage:
        'The incident escaped containment. Review the workflow and recover without guessing.',
    targets: <FlameMiniGameTargetModel>[
      FlameMiniGameTargetModel(
        id: 'inspect_logs',
        label: 'Inspect logs',
        hint: 'Start with evidence.',
        isCorrect: true,
        feedback: 'Logs inspected.',
      ),
      FlameMiniGameTargetModel(
        id: 'reproduce_bug',
        label: 'Reproduce bug',
        hint: 'Confirm the failure path.',
        isCorrect: true,
        feedback: 'Bug reproduced.',
      ),
      FlameMiniGameTargetModel(
        id: 'patch_state',
        label: 'Patch state',
        hint: 'Fix the confirmed cause.',
        isCorrect: true,
        feedback: 'Patch applied.',
      ),
      FlameMiniGameTargetModel(
        id: 'run_tests',
        label: 'Run tests',
        hint: 'Verify the patch.',
        isCorrect: true,
        feedback: 'Tests completed.',
      ),
      FlameMiniGameTargetModel(
        id: 'open_pr',
        label: 'Open PR',
        hint: 'Create review evidence.',
        isCorrect: true,
        feedback: 'Pull request opened.',
      ),
      FlameMiniGameTargetModel(
        id: 'deploy_fix',
        label: 'Deploy fix',
        hint: 'Release only when verified.',
        isCorrect: true,
        feedback: 'Fix deployed.',
      ),
    ],
  );

  final DeveloperIncidentEngine incident = DeveloperIncidentEngine();

  DeveloperIncidentAction? _processingAction;
  double _processingRemaining = 0;
  double _processingDuration = 0;
  double _tickAccumulator = 0;
  double _visualTime = 0;
  double _dangerFlash = 0;

  bool get _reducedMotion => AnimationService.instance.isReducedMotion;
  int get productionHealth => incident.health;
  int get chaosLevel => incident.chaos;
  String get currentTask => incident.currentTask;
  DeveloperIncidentAction? get processingAction => _processingAction;

  @override
  void update(double dt) {
    super.update(dt);
    _visualTime += dt;
    _dangerFlash = math.max(0, _dangerFlash - dt);

    if (isFinished || incident.isComplete || incident.isFailed) {
      return;
    }

    _tickAccumulator += dt;
    while (_tickAccumulator >= 1) {
      _tickAccumulator -= 1;
      incident.tick();
      if (incident.isFailed) {
        comboCount.value = 0;
        feedbackMessage.value = incident.currentTask;
        unawaited(AudioService.instance.playSoundEffect('alert_buzz'));
        return;
      }
    }

    final action = _processingAction;
    if (action == null) {
      return;
    }

    _processingRemaining -= dt;
    if (_processingRemaining > 0) {
      return;
    }

    _processingAction = null;
    _processingRemaining = 0;
    final outcome = incident.resolve(action);
    _syncCompletedActions();
    feedbackMessage.value = outcome.message;

    if (outcome.disciplined) {
      if (outcome.completed) {
        comboCount.value += 1;
      }
      unawaited(AudioService.instance.playSoundEffect('notification_ping'));
      HapticFeedback.lightImpact();
    } else {
      comboCount.value = 0;
      _dangerFlash = _reducedMotion ? 0 : 0.32;
      unawaited(AudioService.instance.playSoundEffect('comedy_bonk'));
      HapticFeedback.heavyImpact();
    }

    if (incident.isComplete) {
      feedbackMessage.value =
          'Production stabilized automatically. Incident workflow complete — continue with the report.';
      unawaited(AudioService.instance.playSoundEffect('notification_ping'));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isFinished ||
        incident.isComplete ||
        incident.isFailed ||
        _processingAction != null) {
      return;
    }

    final tap = Offset(
      event.localPosition.x,
      event.localPosition.y,
    );
    final actions = DeveloperIncidentAction.values;
    for (var index = 0; index < actions.length; index += 1) {
      if (!_actionRect(index).inflate(5).contains(tap)) {
        continue;
      }
      _startAction(actions[index]);
      HapticFeedback.selectionClick();
      return;
    }
  }

  void _startAction(DeveloperIncidentAction action) {
    if (incident.completedActions.contains(action)) {
      feedbackMessage.value =
          '${action.label} already finished. ${incident.currentTask}';
      return;
    }

    _processingAction = action;
    _processingDuration = action.processingSeconds;
    _processingRemaining = _processingDuration;
    feedbackMessage.value = '${action.label} processing…';
    unawaited(AudioService.instance.playSoundEffect('choice_select'));
  }

  void _syncCompletedActions() {
    selectedTargetIds.value = Set<String>.unmodifiable(
      incident.completedActions.map((action) => action.id),
    );
  }

  @override
  void clearSelection() {
    feedbackMessage.value =
        'Completed workflow tasks stay completed. Continue with: ${incident.currentTask}';
  }

  // The live incident workstation replaces BaseMiniGame's selectable-card
  // renderer while reusing its timer/result contract.
  // ignore: must_call_super
  @override
  void render(Canvas canvas) {
    final bounds = Offset.zero & Size(size.x, size.y);
    _drawBackground(canvas, bounds);
    _drawIncidentHud(canvas);
    _drawCurrentTask(canvas);
    _drawEventFeed(canvas);
    _drawToolGrid(canvas);
    _drawProcessingBar(canvas);
    _drawDangerTreatment(canvas, bounds);
  }

  void _drawBackground(Canvas canvas, Rect bounds) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF071322),
            Color(0xFF111326),
            Color(0xFF05070D),
          ],
        ).createShader(bounds),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFF70D6FF).withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const spacing = 32.0;
    final motion = _reducedMotion ? 0.0 : (_visualTime * 9) % spacing;
    for (double x = -spacing + motion; x < size.x + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = -spacing + motion; y < size.y + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
  }

  void _drawIncidentHud(Canvas canvas) {
    final healthColor = productionHealth >= 70
        ? const Color(0xFF56F2C3)
        : productionHealth >= 35
            ? const Color(0xFFFFC857)
            : const Color(0xFFFF5C70);

    _drawText(
      canvas,
      'LIVE INCIDENT • LOGIN STATE',
      const Offset(18, 14),
      fontSize: 10,
      color: const Color(0xFFFF80AD),
      fontWeight: FontWeight.w900,
      maxWidth: size.x - 36,
    );
    _drawText(
      canvas,
      'Production health $productionHealth%',
      const Offset(18, 34),
      fontSize: 15,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      maxWidth: size.x * 0.66,
    );

    final barRect = Rect.fromLTWH(18, 58, math.max(100, size.x - 150), 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.09),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barRect.width * (productionHealth / 100),
          barRect.height,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = healthColor,
    );

    final chaosRect = Rect.fromLTWH(math.max(18, size.x - 116), 28, 98, 42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chaosRect, const Radius.circular(14)),
      Paint()..color = const Color(0xFF1B0D17).withValues(alpha: 0.92),
    );
    _drawText(
      canvas,
      'CHAOS $chaosLevel',
      Offset(chaosRect.left + 10, chaosRect.top + 8),
      fontSize: 10,
      color: chaosLevel == 0 ? const Color(0xFF56F2C3) : const Color(0xFFFF7A8E),
      fontWeight: FontWeight.w900,
      maxWidth: chaosRect.width - 20,
      textAlign: TextAlign.center,
    );
    _drawText(
      canvas,
      '${remainingSeconds.value}s LEFT',
      Offset(chaosRect.left + 10, chaosRect.top + 23),
      fontSize: 8,
      color: Colors.white60,
      fontWeight: FontWeight.w800,
      maxWidth: chaosRect.width - 20,
      textAlign: TextAlign.center,
    );
  }

  void _drawCurrentTask(Canvas canvas) {
    final rect = Rect.fromLTWH(18, 78, math.max(120, size.x - 36), 54);
    final recommended = incident.recommendedAction;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()..color = const Color(0xFF0A1220).withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF70D6FF).withValues(alpha: 0.42),
    );
    _drawText(
      canvas,
      incident.isComplete ? 'INCIDENT CONTAINED' : 'AUTO TASK • ${recommended.shortLabel}',
      Offset(rect.left + 12, rect.top + 8),
      fontSize: 8.5,
      color: incident.isComplete
          ? const Color(0xFF56F2C3)
          : const Color(0xFF70D6FF),
      fontWeight: FontWeight.w900,
      maxWidth: rect.width - 24,
    );
    _drawText(
      canvas,
      currentTask,
      Offset(rect.left + 12, rect.top + 23),
      fontSize: 10.5,
      color: Colors.white,
      fontWeight: FontWeight.w700,
      maxWidth: rect.width - 24,
      maxLines: 2,
    );
  }

  void _drawEventFeed(Canvas canvas) {
    final rect = Rect.fromLTWH(18, 142, math.max(120, size.x - 36), 82);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );
    _drawText(
      canvas,
      'LIVE EVENT FEED',
      Offset(rect.left + 10, rect.top + 8),
      fontSize: 8,
      color: const Color(0xFFFFC857),
      fontWeight: FontWeight.w900,
      maxWidth: rect.width - 20,
    );

    final visible = incident.feed.reversed.take(3).toList().reversed.toList();
    var y = rect.top + 25;
    for (final line in visible) {
      _drawText(
        canvas,
        '› $line',
        Offset(rect.left + 10, y),
        fontSize: 7.6,
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        maxWidth: rect.width - 20,
        maxLines: 1,
      );
      y += 17;
    }
  }

  void _drawToolGrid(Canvas canvas) {
    final actions = DeveloperIncidentAction.values;
    for (var index = 0; index < actions.length; index += 1) {
      final action = actions[index];
      final rect = _actionRect(index);
      final completed = incident.completedActions.contains(action);
      final processing = _processingAction == action;
      final recommended = !incident.isComplete &&
          !incident.isFailed &&
          incident.recommendedAction == action;
      final risky = !completed && _isRiskyNow(action);

      final accent = completed
          ? const Color(0xFF56F2C3)
          : processing
              ? const Color(0xFFFFC857)
              : risky
                  ? const Color(0xFFFF6B7A)
                  : recommended
                      ? const Color(0xFF70D6FF)
                      : const Color(0xFF7B86A1);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              accent.withValues(alpha: completed ? 0.24 : 0.13),
              const Color(0xFF090C14).withValues(alpha: 0.96),
            ],
          ).createShader(rect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = recommended ? 1.8 : 1.0
          ..color = accent.withValues(alpha: recommended ? 0.90 : 0.46),
      );

      _drawText(
        canvas,
        action.shortLabel,
        Offset(rect.left + 10, rect.top + 8),
        fontSize: 10,
        color: accent,
        fontWeight: FontWeight.w900,
        maxWidth: rect.width - 20,
      );
      _drawText(
        canvas,
        completed
            ? 'DONE'
            : processing
                ? 'PROCESSING…'
                : risky
                    ? 'RISKY NOW'
                    : recommended
                        ? 'NEXT TASK'
                        : 'AVAILABLE',
        Offset(rect.left + 10, rect.top + 27),
        fontSize: 7.5,
        color: Colors.white70,
        fontWeight: FontWeight.w800,
        maxWidth: rect.width - 20,
      );
    }
  }

  Rect _actionRect(int index) {
    final width = math.max(300.0, size.x);
    const gap = 9.0;
    const horizontalPadding = 18.0;
    final cardWidth = (width - horizontalPadding * 2 - gap) / 2;
    final row = index ~/ 2;
    final column = index % 2;
    return Rect.fromLTWH(
      horizontalPadding + column * (cardWidth + gap),
      236 + row * 61,
      cardWidth,
      52,
    );
  }

  bool _isRiskyNow(DeveloperIncidentAction action) {
    switch (action) {
      case DeveloperIncidentAction.inspectLogs:
        return false;
      case DeveloperIncidentAction.reproduceBug:
        return !incident.completedActions.contains(
          DeveloperIncidentAction.inspectLogs,
        );
      case DeveloperIncidentAction.patchState:
        return !incident.completedActions.contains(
          DeveloperIncidentAction.reproduceBug,
        );
      case DeveloperIncidentAction.runTests:
        return !incident.completedActions.contains(
          DeveloperIncidentAction.patchState,
        );
      case DeveloperIncidentAction.openPullRequest:
        return !incident.completedActions.contains(
          DeveloperIncidentAction.runTests,
        );
      case DeveloperIncidentAction.deployFix:
        return !incident.completedActions.contains(
              DeveloperIncidentAction.patchState,
            ) ||
            !incident.completedActions.contains(
              DeveloperIncidentAction.runTests,
            ) ||
            !incident.completedActions.contains(
              DeveloperIncidentAction.openPullRequest,
            );
    }
  }

  void _drawProcessingBar(Canvas canvas) {
    final action = _processingAction;
    if (action == null) {
      return;
    }
    final progress = _processingDuration <= 0
        ? 1.0
        : (1 - _processingRemaining / _processingDuration).clamp(0.0, 1.0);
    final rect = Rect.fromLTWH(18, math.max(420, size.y - 34), size.x - 36, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(9)),
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left, rect.top, rect.width * progress, rect.height),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0xFFFFC857).withValues(alpha: 0.82),
    );
    _drawText(
      canvas,
      '${action.label} ${(progress * 100).round()}%',
      Offset(rect.left + 8, rect.top + 4),
      fontSize: 7.5,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      maxWidth: rect.width - 16,
      textAlign: TextAlign.center,
    );
  }

  void _drawDangerTreatment(Canvas canvas, Rect bounds) {
    final critical = productionHealth < 35 || _dangerFlash > 0;
    if (!critical) {
      return;
    }
    final pulse = _reducedMotion ? 0.45 : (math.sin(_visualTime * 10) + 1) / 2;
    canvas.drawRect(
      bounds,
      Paint()
        ..color = const Color(0xFFFF4059).withValues(
          alpha: 0.025 + pulse * 0.055,
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
          height: 1.08,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? math.max(80.0, size.x - 40));
    painter.paint(canvas, offset);
  }
}
