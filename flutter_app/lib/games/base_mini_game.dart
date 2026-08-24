import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/flame_mini_game_model.dart';
import '../models/game_visual_settings_model.dart';
import '../services/game_visual_settings_service.dart';
import '../services/animation_service.dart';

abstract class BaseMiniGame extends FlameGame with TapCallbacks {
  BaseMiniGame({required this.definition});

  final FlameMiniGameDefinitionModel definition;
  final ValueNotifier<int> remainingSeconds = ValueNotifier<int>(0);
  final ValueNotifier<Set<String>> selectedTargetIds =
      ValueNotifier<Set<String>>(<String>{});
  final ValueNotifier<String> feedbackMessage = ValueNotifier<String>(
    'Tap an incident card inside the game arena.',
  );
  final ValueNotifier<int> comboCount = ValueNotifier<int>(0);

  final List<_TapBurst> _tapBursts = <_TapBurst>[];
  final math.Random _random = math.Random(137);
  final List<_BackgroundParticle> _particles = <_BackgroundParticle>[];

  double _elapsed = 0;
  bool _finished = false;
  String? _lastTappedTargetId;
  double _lastTapAt = -10;

  int get elapsedSeconds => _elapsed.floor();
  bool get isFinished => _finished;
  GameVisualQuality get _visualQuality =>
      GameVisualSettingsService.instance.currentQuality;
  double get _visualTime =>
      AnimationService.instance.isReducedMotion ? 0 : _elapsed;

  Offset get sceneFeedbackOffset => Offset.zero;

  String progressSummary(Set<String> selected) =>
      '${selected.length} selected • ${definition.successThreshold} correct targets required';

  bool get allowClearSelection => true;
  String get submitActionLabel => 'Submit Investigation';
  String get retryActionLabel => 'Retry';

  String resultDialogTitle(FlameMiniGameResultModel result) =>
      result.isSuccess ? 'Incident contained!' : 'Chaos report generated';

  List<String> resultSummaryLabels(FlameMiniGameResultModel result) => <String>[
        'XP +${result.xpEarned}',
        'Correct ${result.correctCount}',
        'Wrong ${result.wrongCount}',
        '${result.elapsedSeconds}s',
      ];

  double targetFeedbackScale(
    FlameMiniGameTargetModel target,
    int index,
  ) => 1;

  Offset targetFeedbackOffset(
    FlameMiniGameTargetModel target,
    int index,
  ) => Offset.zero;

  void onTargetTapped({
    required FlameMiniGameTargetModel target,
    required int index,
    required Offset tapPosition,
    required bool isAdding,
  }) {}

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    remainingSeconds.value = definition.timeLimitSeconds;
    _particles.addAll(
      List<_BackgroundParticle>.generate(
        42,
        (index) => _BackgroundParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: 0.8 + _random.nextDouble() * 2.4,
          speed: 0.25 + _random.nextDouble() * 0.9,
          phase: _random.nextDouble() * math.pi * 2,
        ),
        growable: false,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_finished) {
      _elapsed += dt;
      final remaining = (definition.timeLimitSeconds - _elapsed)
          .ceil()
          .clamp(0, definition.timeLimitSeconds)
          .toInt();
      if (remainingSeconds.value != remaining) {
        remainingSeconds.value = remaining;
      }
      if (remaining <= 0) {
        _finished = true;
        feedbackMessage.value = 'Time is up. Submit the current investigation.';
      }
    }

    for (final burst in _tapBursts) {
      burst.age += dt;
    }
    _tapBursts.removeWhere((burst) => burst.age >= burst.duration);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_finished || definition.targets.isEmpty) {
      return;
    }

    final tap = event.localPosition.toOffset();
    for (var index = 0; index < definition.targets.length; index += 1) {
      final rect = targetRectFor(index, definition.targets.length);
      if (!rect.inflate(6).contains(tap)) {
        continue;
      }

      final target = definition.targets[index];
      final isAdding = !selectedTargetIds.value.contains(target.id);
      toggleTarget(target.id);
      feedbackMessage.value = target.hint;
      _tapBursts.add(
        _TapBurst(
          center: tap,
          color: target.isCorrect
              ? const Color(0xFF69F0AE)
              : const Color(0xFFFFC857),
        ),
      );
      onTargetTapped(
        target: target,
        index: index,
        tapPosition: tap,
        isAdding: isAdding,
      );
      HapticFeedback.selectionClick();
      break;
    }
  }

  void toggleTarget(String targetId) {
    if (_finished) {
      return;
    }
    final next = Set<String>.from(selectedTargetIds.value);
    final isAdding = !next.contains(targetId);
    if (isAdding) {
      next.add(targetId);
    } else {
      next.remove(targetId);
    }
    selectedTargetIds.value = Set<String>.unmodifiable(next);

    if (isAdding &&
        _lastTappedTargetId != targetId &&
        _elapsed - _lastTapAt <= 2.4) {
      comboCount.value += 1;
    } else if (isAdding) {
      comboCount.value = 1;
    } else {
      comboCount.value = comboCount.value > 0 ? comboCount.value - 1 : 0;
    }
    _lastTappedTargetId = targetId;
    _lastTapAt = _elapsed;
  }

  void clearSelection() {
    selectedTargetIds.value = const <String>{};
    comboCount.value = 0;
    feedbackMessage.value =
        'Investigation cleared. Tap incident cards to select them.';
  }

  FlameMiniGameResultModel finish() {
    _finished = true;
    final selected = selectedTargetIds.value;
    final correctIds = definition.targets
        .where((target) => target.isCorrect)
        .map((target) => target.id)
        .toSet();
    final correctCount = selected.where(correctIds.contains).length;
    final wrongCount = selected.where((id) => !correctIds.contains(id)).length;
    final passedThreshold = correctCount >= definition.successThreshold;
    final isSuccess = passedThreshold && wrongCount == 0;

    feedbackMessage.value = isSuccess
        ? 'Production blockers isolated. Incident contained.'
        : 'Investigation incomplete. Review the incident report.';

    return FlameMiniGameResultModel(
      gameId: definition.id,
      kind: definition.kind,
      title: definition.title,
      completedAt: DateTime.now(),
      isSuccess: isSuccess,
      correctCount: correctCount,
      wrongCount: wrongCount,
      elapsedSeconds: elapsedSeconds,
      xpEarned: isSuccess ? definition.successXp : definition.failureXp,
      scoreImpact:
          isSuccess ? definition.successScoreImpact : definition.failureScoreImpact,
      selectedTargetIds: Set<String>.unmodifiable(selected),
      message: isSuccess ? definition.successMessage : definition.failureMessage,
    );
  }

  void disposeNotifiers() {
    remainingSeconds.dispose();
    selectedTargetIds.dispose();
    feedbackMessage.dispose();
    comboCount.dispose();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final sceneOffset = sceneFeedbackOffset;
    canvas.save();
    canvas.translate(sceneOffset.dx, sceneOffset.dy);

    final rect = Offset.zero & Size(size.x, size.y);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _backgroundColors,
        stops: const <double>[0, 0.52, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    _drawMovingGrid(canvas);
    _drawAmbientParticles(canvas);
    _drawMissionGlow(canvas);
    _drawTargetCards(canvas);
    _drawTapBursts(canvas);
    _drawHud(canvas);
    _drawVignette(canvas);
    canvas.restore();
  }

  List<Color> get _backgroundColors {
    switch (definition.kind) {
      case FlameMiniGameKind.bugHuntRoom:
        return const <Color>[
          Color(0xFF090D21),
          Color(0xFF35153B),
          Color(0xFF070913),
        ];
      case FlameMiniGameKind.dataCleanupRace:
        return const <Color>[
          Color(0xFF071D1B),
          Color(0xFF145A4B),
          Color(0xFF06110F),
        ];
      case FlameMiniGameKind.blueprintSafetyPuzzle:
        return const <Color>[
          Color(0xFF101522),
          Color(0xFF1E4E78),
          Color(0xFF071019),
        ];
    }
  }

  void _drawMovingGrid(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.045)
      ..strokeWidth = 1;
    const spacing = 38.0;
    final shift = (_visualTime * 18) % spacing;
    for (double x = -spacing + shift; x < size.x + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }
    for (double y = -spacing + shift; y < size.y + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }

  void _drawAmbientParticles(Canvas canvas) {
    if (_visualQuality == GameVisualQuality.low) {
      return;
    }
    final paint = Paint()..color = Colors.white.withOpacity(0.10);
    for (final particle in _particles) {
      final y = (particle.y + _visualTime * particle.speed * 0.018) % 1;
      final x = particle.x + math.sin(_visualTime * 0.9 + particle.phase) * 0.02;
      canvas.drawCircle(
        Offset(x * size.x, y * size.y),
        particle.radius,
        paint,
      );
    }
  }

  void _drawMissionGlow(Canvas canvas) {
    if (_visualQuality != GameVisualQuality.high) {
      return;
    }
    final pulse = (math.sin(_visualTime * 2.2) + 1) / 2;
    canvas.drawCircle(
      Offset(size.x * 0.52, size.y * 0.44),
      size.x * (0.20 + pulse * 0.035),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFF4D8D).withOpacity(0.16),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.x * 0.52, size.y * 0.44),
            radius: size.x * 0.3,
          ),
        ),
    );
  }

  void _drawTargetCards(Canvas canvas) {
    for (var index = 0; index < definition.targets.length; index += 1) {
      final target = definition.targets[index];
      final baseRect = targetRectFor(index, definition.targets.length);
      final offset = targetFeedbackOffset(target, index);
      final scale = targetFeedbackScale(target, index);
      final rect = Rect.fromCenter(
        center: baseRect.center + offset,
        width: baseRect.width * scale,
        height: baseRect.height * scale,
      );
      final selected = selectedTargetIds.value.contains(target.id);
      final color = selected
          ? const Color(0xFF69F0AE)
          : const Color(0xFFFFC857);

      final cardPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF121522).withOpacity(0.96),
            color.withOpacity(selected ? 0.22 : 0.08),
          ],
        ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        cardPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.5 : 1.2
          ..color = color.withOpacity(selected ? 0.9 : 0.32),
      );

      final titlePainter = TextPainter(
        text: TextSpan(
          text: target.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: rect.width - 24);
      titlePainter.paint(canvas, Offset(rect.left + 12, rect.top + 10));

      final hintPainter = TextPainter(
        text: TextSpan(
          text: target.hint,
          style: TextStyle(
            color: Colors.white.withOpacity(0.64),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: rect.width - 24);
      hintPainter.paint(canvas, Offset(rect.left + 12, rect.bottom - 34));
    }
  }

  Rect targetRectFor(int index, int count) {
    final padding = size.x < 520 ? 18.0 : 28.0;
    final gap = size.x < 520 ? 10.0 : 16.0;
    final columns = size.x < 520 ? 2 : 3;
    final rows = (count / columns).ceil();
    final cardWidth = (size.x - padding * 2 - gap * (columns - 1)) / columns;
    final availableHeight = size.y - 128;
    final cardHeight = math.min(
      118.0,
      (availableHeight - gap * (rows - 1)) / rows,
    );
    final totalHeight = cardHeight * rows + gap * (rows - 1);
    final startY = (size.y - totalHeight) / 2 + 18;
    final row = index ~/ columns;
    final column = index % columns;
    return Rect.fromLTWH(
      padding + column * (cardWidth + gap),
      startY + row * (cardHeight + gap),
      cardWidth,
      cardHeight,
    );
  }

  void _drawTapBursts(Canvas canvas) {
    for (final burst in _tapBursts) {
      final progress = (burst.age / burst.duration).clamp(0.0, 1.0);
      canvas.drawCircle(
        burst.center,
        12 + progress * 34,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - progress)
          ..color = burst.color.withOpacity(0.7 * (1 - progress)),
      );
    }
  }

  void _drawHud(Canvas canvas) {
    final timerPainter = TextPainter(
      text: TextSpan(
        text: '${remainingSeconds.value}s',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    timerPainter.paint(canvas, const Offset(18, 16));

    final selectedPainter = TextPainter(
      text: TextSpan(
        text: '${selectedTargetIds.value.length} / ${definition.successThreshold}',
        style: TextStyle(
          color: Colors.white.withOpacity(0.82),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    selectedPainter.paint(
      canvas,
      Offset(size.x - selectedPainter.width - 18, 18),
    );
  }

  void _drawVignette(Canvas canvas) {
    if (_visualQuality == GameVisualQuality.low) {
      return;
    }
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.transparent,
            Colors.black.withOpacity(0.52),
          ],
          stops: const <double>[0.54, 1],
        ).createShader(Offset.zero & Size(size.x, size.y)),
    );
  }
}

class _TapBurst {
  _TapBurst({required this.center, required this.color});

  final Offset center;
  final Color color;
  double age = 0;
  final double duration = 0.5;
}

class _BackgroundParticle {
  _BackgroundParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
  });

  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
}
