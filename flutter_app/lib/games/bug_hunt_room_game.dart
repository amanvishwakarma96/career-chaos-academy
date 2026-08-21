import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/flame_mini_game_model.dart';
import '../models/score_model.dart';
import '../services/animation_service.dart';
import '../services/audio_service.dart';
import 'base_mini_game.dart';

class BugHuntRoomGame extends BaseMiniGame {
  BugHuntRoomGame({int? seed}) : super(definition: _buildRuntimeDefinition(seed));

  static const FlameMiniGameDefinitionModel gameDefinition =
      FlameMiniGameDefinitionModel(
    id: 'flame_bug_hunt_room',
    kind: FlameMiniGameKind.bugHuntRoom,
    title: 'Bug Hunt Room',
    subtitle: 'Find the risky defects before the release train becomes a clown car.',
    instructions:
        'Select only the real production blockers. Every run contains a different incident mix. Wrong calls accelerate the incident clock; fast correct streaks briefly slow it.',
    timeLimitSeconds: 45,
    successThreshold: 3,
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
        'Bug hunt cleared. QA nods respectfully. The release train remains on tracks.',
    failureMessage:
        'The incident escaped containment. Useful chaos, but still chaos.',
    targets: <FlameMiniGameTargetModel>[
      FlameMiniGameTargetModel(
        id: 'null_token',
        label: 'Null token after refresh',
        hint: 'Auth blockers stop users cold.',
        isCorrect: true,
        feedback: 'Correct: token refresh bugs block sessions.',
      ),
      FlameMiniGameTargetModel(
        id: 'ios_keyboard_overlap',
        label: 'iOS keyboard hides submit',
        hint: 'Blocks a core flow on one platform.',
        isCorrect: true,
        feedback: 'Correct: platform blockers need release attention.',
      ),
      FlameMiniGameTargetModel(
        id: 'payment_double_tap',
        label: 'Double-tap creates duplicate payment',
        hint: 'Money flow issues are high priority.',
        isCorrect: true,
        feedback: 'Correct: duplicate payment risk is serious.',
      ),
      FlameMiniGameTargetModel(
        id: 'coffee_stain',
        label: 'Coffee stain on Jira screenshot',
        hint: 'Funny, not a production blocker.',
        isCorrect: false,
        feedback: 'Not a blocker. Hydrate the screenshot later.',
      ),
      FlameMiniGameTargetModel(
        id: 'variable_name_vibe',
        label: 'Variable name has bad vibes',
        hint: 'Refactor later unless it causes risk.',
        isCorrect: false,
        feedback: 'Code vibes are real, but not release blockers.',
      ),
    ],
  );

  static const List<FlameMiniGameTargetModel> _correctPool =
      <FlameMiniGameTargetModel>[
    FlameMiniGameTargetModel(
      id: 'null_token',
      label: 'Null token after refresh',
      hint: 'Auth blockers stop users cold.',
      isCorrect: true,
      feedback: 'Correct: token refresh bugs block sessions.',
    ),
    FlameMiniGameTargetModel(
      id: 'ios_keyboard_overlap',
      label: 'iOS keyboard hides submit',
      hint: 'Blocks a core flow on one platform.',
      isCorrect: true,
      feedback: 'Correct: platform blockers need release attention.',
    ),
    FlameMiniGameTargetModel(
      id: 'payment_double_tap',
      label: 'Double-tap creates duplicate payment',
      hint: 'Money flow issues are high priority.',
      isCorrect: true,
      feedback: 'Correct: duplicate payment risk is serious.',
    ),
    FlameMiniGameTargetModel(
      id: 'offline_sync_loss',
      label: 'Offline draft disappears after reconnect',
      hint: 'Users lose real work when sync recovery fails.',
      isCorrect: true,
      feedback: 'Correct: destructive sync loss is a release blocker.',
    ),
    FlameMiniGameTargetModel(
      id: 'admin_leak',
      label: 'Restricted admin field visible to normal user',
      hint: 'Authorization leaks are production risks.',
      isCorrect: true,
      feedback: 'Correct: access-control leaks require immediate attention.',
    ),
    FlameMiniGameTargetModel(
      id: 'checkout_crash',
      label: 'Checkout crashes on slow network',
      hint: 'Core revenue flow cannot fail under normal network stress.',
      isCorrect: true,
      feedback: 'Correct: reproducible checkout crashes block release.',
    ),
  ];

  static const List<FlameMiniGameTargetModel> _decoyPool =
      <FlameMiniGameTargetModel>[
    FlameMiniGameTargetModel(
      id: 'coffee_stain',
      label: 'Coffee stain on Jira screenshot',
      hint: 'Funny, not a production blocker.',
      isCorrect: false,
      feedback: 'Not a blocker. Hydrate the screenshot later.',
    ),
    FlameMiniGameTargetModel(
      id: 'variable_name_vibe',
      label: 'Variable name has bad vibes',
      hint: 'Refactor later unless it causes risk.',
      isCorrect: false,
      feedback: 'Code vibes are real, but not release blockers.',
    ),
    FlameMiniGameTargetModel(
      id: 'button_blue',
      label: 'Button blue is 2% less dramatic',
      hint: 'Visual polish can wait behind production risk.',
      isCorrect: false,
      feedback: 'Not a blocker. The button can survive being slightly less cinematic.',
    ),
    FlameMiniGameTargetModel(
      id: 'comment_grammar',
      label: 'TODO comment has bad grammar',
      hint: 'Embarrassing is not the same as release-blocking.',
      isCorrect: false,
      feedback: 'Not a blocker. Fix the sentence after the incident.',
    ),
    FlameMiniGameTargetModel(
      id: 'emoji_commit',
      label: 'Commit message contains too many emojis',
      hint: 'Questionable taste is not a production outage.',
      isCorrect: false,
      feedback: 'Not a blocker. The emoji situation can be handled diplomatically.',
    ),
  ];

  static FlameMiniGameDefinitionModel _buildRuntimeDefinition(int? seed) {
    final random = math.Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final correct = List<FlameMiniGameTargetModel>.from(_correctPool)..shuffle(random);
    final decoys = List<FlameMiniGameTargetModel>.from(_decoyPool)..shuffle(random);
    final targets = <FlameMiniGameTargetModel>[
      ...correct.take(3),
      ...decoys.take(2),
    ]..shuffle(random);

    return FlameMiniGameDefinitionModel(
      id: gameDefinition.id,
      kind: gameDefinition.kind,
      title: gameDefinition.title,
      subtitle: gameDefinition.subtitle,
      instructions: gameDefinition.instructions,
      timeLimitSeconds: gameDefinition.timeLimitSeconds,
      successThreshold: gameDefinition.successThreshold,
      successScoreImpact: gameDefinition.successScoreImpact,
      failureScoreImpact: gameDefinition.failureScoreImpact,
      successXp: gameDefinition.successXp,
      failureXp: gameDefinition.failureXp,
      successMessage: gameDefinition.successMessage,
      failureMessage: gameDefinition.failureMessage,
      targets: List<FlameMiniGameTargetModel>.unmodifiable(targets),
    );
  }

  static const double _comboWindowSeconds = 2.4;
  static const double _targetFeedbackDuration = 0.34;
  static const double _wrongShakeDuration = 0.28;
  static const double _wrongClockPenaltyDuration = 0.85;
  static const double _comboClockReliefDuration = 0.70;

  final math.Random _juiceRandom = math.Random(911);
  final List<_BugHuntImpactParticle> _impactParticles =
      <_BugHuntImpactParticle>[];

  double _juiceElapsed = 0;
  double _lastCorrectHitAt = -10;
  String? _lastCorrectTargetId;
  int? _feedbackTargetIndex;
  bool _feedbackWasCorrect = false;
  double _targetFeedbackAge = _targetFeedbackDuration;
  double _wrongShakeRemaining = 0;
  double _wrongClockPenaltyRemaining = 0;
  double _comboClockReliefRemaining = 0;
  double _incidentPressure = 18;
  int _mistakeCount = 0;

  bool get _reducedMotion => AnimationService.instance.isReducedMotion;
  int get incidentPressure => _incidentPressure.round().clamp(0, 100);
  int get mistakeCount => _mistakeCount;

  @override
  void update(double dt) {
    final clockScale = _wrongClockPenaltyRemaining > 0
        ? 4.0
        : _comboClockReliefRemaining > 0
            ? 0.30
            : 1.0;
    super.update(dt * clockScale);

    _juiceElapsed += dt;
    _targetFeedbackAge += dt;
    _wrongShakeRemaining = math.max(0, _wrongShakeRemaining - dt);
    _wrongClockPenaltyRemaining =
        math.max(0, _wrongClockPenaltyRemaining - dt);
    _comboClockReliefRemaining = math.max(0, _comboClockReliefRemaining - dt);
    _incidentPressure = math.min(100, _incidentPressure + dt * 0.55);

    for (final particle in _impactParticles) {
      particle.age += dt;
      particle.position += particle.velocity * dt;
      particle.velocity = Offset(
        particle.velocity.dx * 0.96,
        particle.velocity.dy * 0.96 + 22 * dt,
      );
    }
    _impactParticles.removeWhere(
      (particle) => particle.age >= particle.duration,
    );
  }

  @override
  void toggleTarget(String targetId) {
    if (isFinished) {
      return;
    }

    final wasSelected = selectedTargetIds.value.contains(targetId);
    final previousCombo = comboCount.value;
    final target = definition.targets.firstWhere(
      (candidate) => candidate.id == targetId,
    );

    super.toggleTarget(targetId);

    if (wasSelected) {
      comboCount.value = 0;
      _lastCorrectTargetId = null;
      _lastCorrectHitAt = -10;
      return;
    }

    if (!target.isCorrect) {
      comboCount.value = 0;
      _lastCorrectTargetId = null;
      _lastCorrectHitAt = -10;
      return;
    }

    final continuesCombo = previousCombo > 0 &&
        _lastCorrectTargetId != targetId &&
        _juiceElapsed - _lastCorrectHitAt <= _comboWindowSeconds;
    comboCount.value = continuesCombo ? previousCombo + 1 : 1;
    _lastCorrectTargetId = targetId;
    _lastCorrectHitAt = _juiceElapsed;
  }

  @override
  void clearSelection() {
    super.clearSelection();
    _lastCorrectTargetId = null;
    _lastCorrectHitAt = -10;
    _feedbackTargetIndex = null;
    _targetFeedbackAge = _targetFeedbackDuration;
    _wrongShakeRemaining = 0;
    _wrongClockPenaltyRemaining = 0;
    _comboClockReliefRemaining = 0;
    _incidentPressure = 18;
    _mistakeCount = 0;
    _impactParticles.clear();
  }

  @override
  void onTargetTapped({
    required FlameMiniGameTargetModel target,
    required int index,
    required Offset tapPosition,
    required bool isAdding,
  }) {
    if (!isAdding) {
      feedbackMessage.value =
          'Selection removed. Keep only real production blockers.';
      return;
    }

    _feedbackTargetIndex = index;
    _feedbackWasCorrect = target.isCorrect;
    _targetFeedbackAge = 0;

    if (target.isCorrect) {
      _incidentPressure = math.max(0, _incidentPressure - 8);
      if (comboCount.value >= 2) {
        _comboClockReliefRemaining = _comboClockReliefDuration;
        feedbackMessage.value =
            '${target.feedback} COMBO x${comboCount.value}: incident clock slowed.';
      } else {
        feedbackMessage.value = target.feedback;
      }
      _spawnImpactParticles(
        tapPosition,
        const Color(0xFF69F0AE),
        count: 14,
      );
      unawaited(
        AudioService.instance.playSoundEffect('notification_ping'),
      );
    } else {
      _mistakeCount += 1;
      _incidentPressure = math.min(100, _incidentPressure + 24);
      _wrongClockPenaltyRemaining = _wrongClockPenaltyDuration;
      feedbackMessage.value =
          '${target.feedback} Wrong call: incident clock accelerating!';
      if (!_reducedMotion) {
        _wrongShakeRemaining = _wrongShakeDuration;
      }
      _spawnImpactParticles(
        tapPosition,
        const Color(0xFFFF6B6B),
        count: 10,
      );
      unawaited(
        AudioService.instance.playSoundEffect('comedy_bonk'),
      );
    }
  }

  @override
  double targetFeedbackScale(
    FlameMiniGameTargetModel target,
    int index,
  ) {
    if (_reducedMotion ||
        index != _feedbackTargetIndex ||
        !_feedbackWasCorrect ||
        _targetFeedbackAge >= _targetFeedbackDuration) {
      return 1;
    }
    final progress =
        (_targetFeedbackAge / _targetFeedbackDuration).clamp(0.0, 1.0);
    return 1 + math.sin(progress * math.pi) * 0.14;
  }

  @override
  Offset targetFeedbackOffset(
    FlameMiniGameTargetModel target,
    int index,
  ) {
    if (_reducedMotion ||
        index != _feedbackTargetIndex ||
        _feedbackWasCorrect ||
        _targetFeedbackAge >= _targetFeedbackDuration) {
      return Offset.zero;
    }
    final progress =
        (_targetFeedbackAge / _targetFeedbackDuration).clamp(0.0, 1.0);
    final decay = 1 - progress;
    return Offset(
      math.sin(progress * math.pi * 8) * 9 * decay,
      0,
    );
  }

  @override
  Offset get sceneFeedbackOffset {
    if (_reducedMotion || _wrongShakeRemaining <= 0) {
      return Offset.zero;
    }
    final progress = 1 - (_wrongShakeRemaining / _wrongShakeDuration);
    final decay = 1 - progress;
    return Offset(
      math.sin(_juiceElapsed * 92) * 7 * decay,
      math.cos(_juiceElapsed * 76) * 4 * decay,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawPressureOverlay(canvas);
    _drawImpactParticles(canvas);
    _drawComboBadge(canvas);
    _drawPressureHud(canvas);
  }

  void _drawPressureOverlay(Canvas canvas) {
    if (incidentPressure < 70) {
      return;
    }
    final intensity = (incidentPressure - 70) / 30;
    final pulse = _reducedMotion ? 0.65 : (math.sin(_juiceElapsed * 8) + 1) / 2;
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()
        ..color = const Color(0xFFFF3B55).withValues(
          alpha: 0.025 + intensity * 0.055 * pulse,
        ),
    );
  }

  void _drawPressureHud(Canvas canvas) {
    final width = math.min(260.0, math.max(170.0, size.x * 0.36));
    final rect = Rect.fromLTWH(18, math.max(78, size.y - 58), width, 32);
    final danger = incidentPressure >= 70;
    final color = danger ? const Color(0xFFFF5C70) : const Color(0xFFFFC857);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()..color = const Color(0xFF080A12).withValues(alpha: 0.90),
    );
    final bar = Rect.fromLTWH(
      rect.left + 8,
      rect.bottom - 8,
      (rect.width - 16) * (incidentPressure / 100),
      3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(4)),
      Paint()..color = color,
    );

    final mode = _wrongClockPenaltyRemaining > 0
        ? 'CLOCK x4'
        : _comboClockReliefRemaining > 0
            ? 'CLOCK x0.3'
            : 'LIVE';
    final painter = TextPainter(
      text: TextSpan(
        text: 'INCIDENT $incidentPressure%  •  $mode',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 16);
    painter.paint(canvas, Offset(rect.left + 8, rect.top + 6));
  }

  void _spawnImpactParticles(
    Offset center,
    Color color, {
    required int count,
  }) {
    if (_reducedMotion) {
      return;
    }
    for (var index = 0; index < count; index += 1) {
      final angle = (math.pi * 2 * index / count) +
          (_juiceRandom.nextDouble() - 0.5) * 0.35;
      final speed = 70 + _juiceRandom.nextDouble() * 90;
      _impactParticles.add(
        _BugHuntImpactParticle(
          position: center,
          velocity: Offset(
            math.cos(angle) * speed,
            math.sin(angle) * speed,
          ),
          radius: 2 + _juiceRandom.nextDouble() * 3.5,
          color: color,
          duration: 0.42 + _juiceRandom.nextDouble() * 0.22,
        ),
      );
    }
  }

  void _drawImpactParticles(Canvas canvas) {
    for (final particle in _impactParticles) {
      final progress = (particle.age / particle.duration).clamp(0.0, 1.0);
      final opacity = (1 - progress) * 0.9;
      canvas.drawCircle(
        particle.position,
        particle.radius * (1 - progress * 0.35),
        Paint()..color = particle.color.withValues(alpha: opacity),
      );
    }
  }

  void _drawComboBadge(Canvas canvas) {
    final combo = comboCount.value;
    if (combo < 2) {
      return;
    }

    final badgeRect = Rect.fromLTWH(
      math.max(18, size.x - 124),
      math.max(78, size.y - 58),
      106,
      32,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(16)),
      Paint()..color = const Color(0xFF69F0AE).withValues(alpha: 0.90),
    );

    final painter = TextPainter(
      text: TextSpan(
        text: 'COMBO x$combo',
        style: const TextStyle(
          color: Color(0xFF06261B),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: badgeRect.width);
    painter.paint(
      canvas,
      Offset(
        badgeRect.center.dx - painter.width / 2,
        badgeRect.center.dy - painter.height / 2,
      ),
    );
  }
}

class _BugHuntImpactParticle {
  _BugHuntImpactParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
    required this.duration,
  });

  Offset position;
  Offset velocity;
  final double radius;
  final Color color;
  final double duration;
  double age = 0;
}
