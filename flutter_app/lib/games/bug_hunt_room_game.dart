import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/flame_mini_game_model.dart';
import '../models/score_model.dart';
import '../services/animation_service.dart';
import '../services/audio_service.dart';
import 'base_mini_game.dart';

class BugHuntRoomGame extends BaseMiniGame {
  BugHuntRoomGame() : super(definition: gameDefinition);

  static const FlameMiniGameDefinitionModel gameDefinition =
      FlameMiniGameDefinitionModel(
    id: 'flame_bug_hunt_room',
    kind: FlameMiniGameKind.bugHuntRoom,
    title: 'Bug Hunt Room',
    subtitle: 'Find the risky defects before the release train becomes a clown car.',
    instructions: 'Select only the real production blockers. Coffee stains and scary comments are not bugs, even if they feel personal.',
    timeLimitSeconds: 45,
    successThreshold: 3,
    successScoreImpact: ScoreModel(skill: 5, discipline: 3, communication: 1, ethics: 1, chaos: -2),
    failureScoreImpact: ScoreModel(skill: 1, discipline: -1, communication: 0, ethics: 0, chaos: 3),
    successXp: 120,
    failureXp: 35,
    successMessage: 'Bug hunt cleared. QA nods respectfully. The release train remains on tracks.',
    failureMessage: 'You chased a coffee stain while the login bug escaped wearing sunglasses. Useful chaos, but still chaos.',
    targets: <FlameMiniGameTargetModel>[
      FlameMiniGameTargetModel(id: 'null_token', label: 'Null token after refresh', hint: 'Auth blockers stop users cold.', isCorrect: true, feedback: 'Correct: token refresh bugs block sessions.'),
      FlameMiniGameTargetModel(id: 'ios_keyboard_overlap', label: 'iOS keyboard hides submit', hint: 'Blocks a core flow on one platform.', isCorrect: true, feedback: 'Correct: platform blockers need release attention.'),
      FlameMiniGameTargetModel(id: 'payment_double_tap', label: 'Double-tap creates duplicate payment', hint: 'Money flow issues are high priority.', isCorrect: true, feedback: 'Correct: duplicate payment risk is serious.'),
      FlameMiniGameTargetModel(id: 'coffee_stain', label: 'Coffee stain on Jira screenshot', hint: 'Funny, not a production blocker.', isCorrect: false, feedback: 'Not a blocker. Hydrate the screenshot later.'),
      FlameMiniGameTargetModel(id: 'variable_name_vibe', label: 'Variable name has bad vibes', hint: 'Refactor later unless it causes risk.', isCorrect: false, feedback: 'Code vibes are real, but not release blockers.'),
    ],
  );

  static const double _comboWindowSeconds = 2.4;
  static const double _targetFeedbackDuration = 0.34;
  static const double _wrongShakeDuration = 0.28;

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

  bool get _reducedMotion => AnimationService.instance.isReducedMotion;

  @override
  void update(double dt) {
    super.update(dt);
    _juiceElapsed += dt;
    _targetFeedbackAge += dt;
    _wrongShakeRemaining = math.max(0, _wrongShakeRemaining - dt);

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
      feedbackMessage.value = 'Selection removed. Keep only real production blockers.';
      return;
    }

    feedbackMessage.value = target.feedback;
    _feedbackTargetIndex = index;
    _feedbackWasCorrect = target.isCorrect;
    _targetFeedbackAge = 0;

    if (target.isCorrect) {
      _spawnImpactParticles(
        tapPosition,
        const Color(0xFF69F0AE),
        count: 14,
      );
      unawaited(
        AudioService.instance.playSoundEffect('notification_ping'),
      );
    } else {
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
    _drawImpactParticles(canvas);
    _drawComboBadge(canvas);
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
        Paint()..color = particle.color.withOpacity(opacity),
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
      Paint()..color = const Color(0xFF69F0AE).withOpacity(0.90),
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
