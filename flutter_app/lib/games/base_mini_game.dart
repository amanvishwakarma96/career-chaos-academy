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
      final rect = _targetRectFor(index, definition.targets.length);
      if (!rect.inflate(6).contains(tap)) {
        continue;
      }

      final target = definition.targets[index];
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

    if (isAdding && _lastTappedTargetId != targetId &&
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
    feedbackMessage.value = 'Investigation cleared. Tap incident cards to select them.';
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
          Color(0xFF07182D),
          Color(0xFF174A76),
          Color(0xFF050D17),
        ];
    }
  }

  Color get _accentColor {
    switch (definition.kind) {
      case FlameMiniGameKind.bugHuntRoom:
        return const Color(0xFFFF4D8D);
      case FlameMiniGameKind.dataCleanupRace:
        return const Color(0xFF56F2C3);
      case FlameMiniGameKind.blueprintSafetyPuzzle:
        return const Color(0xFF66B8FF);
    }
  }

  void _drawMovingGrid(Canvas canvas) {
    final spacing = definition.kind == FlameMiniGameKind.blueprintSafetyPuzzle
        ? 28.0
        : 34.0;
    final offset = (_visualTime * 11) % spacing;
    final gridPaint = Paint()
      ..color = _accentColor.withOpacity(0.055)
      ..strokeWidth = 1;
    for (double x = -spacing + offset; x < size.x + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = -spacing + offset; y < size.y + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
  }

  void _drawAmbientParticles(Canvas canvas) {
    final budget = math.min(_particles.length, _visualQuality.particleBudget);
    for (var index = 0; index < budget; index += 1) {
      final particle = _particles[index];
      final x = particle.x * size.x +
          math.sin(_visualTime * particle.speed + particle.phase) * 14;
      final y = ((particle.y * size.y) - (_visualTime * 8 * particle.speed)) %
          math.max(1.0, size.y);
      final particlePaint = Paint()
        ..color = _accentColor.withOpacity(0.08 + particle.radius * 0.025)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(x, y), particle.radius, particlePaint);
    }
  }

  void _drawMissionGlow(Canvas canvas) {
    final pulse = (math.sin(_visualTime * 1.4) + 1) / 2;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          _accentColor.withOpacity(0.10 + pulse * 0.05),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.x * 0.5, size.y * 0.52),
          radius: math.min(size.x, size.y) * 0.5,
        ),
      );
    canvas.drawRect(Offset.zero & Size(size.x, size.y), glowPaint);
  }

  void _drawTargetCards(Canvas canvas) {
    final selected = selectedTargetIds.value;
    final targets = definition.targets;
    for (var index = 0; index < targets.length; index += 1) {
      final target = targets[index];
      final rect = _targetRectFor(index, targets.length);
      final isSelected = selected.contains(target.id);
      final floatOffset = math.sin(_visualTime * 1.8 + index * 0.8) *
          (_visualQuality == GameVisualQuality.performance ? 1.5 : 3.5);
      final animatedRect = rect.shift(Offset(0, floatOffset));
      final pulse = (math.sin(_visualTime * 3 + index) + 1) / 2;

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          animatedRect.shift(const Offset(0, 7)),
          const Radius.circular(18),
        ),
        shadowPaint,
      );

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            isSelected
                ? _accentColor.withOpacity(0.88)
                : Colors.white.withOpacity(0.16),
            isSelected
                ? _accentColor.withOpacity(0.38)
                : Colors.black.withOpacity(0.42),
          ],
        ).createShader(animatedRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(animatedRect, const Radius.circular(18)),
        fillPaint,
      );

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.4 : 1.1
        ..color = isSelected
            ? Colors.white.withOpacity(0.82 + pulse * 0.15)
            : Colors.white.withOpacity(0.20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(animatedRect, const Radius.circular(18)),
        borderPaint,
      );

      final iconCenter = Offset(animatedRect.left + 28, animatedRect.center.dy);
      canvas.drawCircle(
        iconCenter,
        17,
        Paint()
          ..color = isSelected
              ? Colors.white.withOpacity(0.90)
              : _accentColor.withOpacity(0.20),
      );
      _drawText(
        canvas,
        _iconFor(target),
        iconCenter.translate(-10, -13),
        fontSize: 18,
        color: isSelected ? Colors.black87 : Colors.white,
        fontWeight: FontWeight.w900,
        maxWidth: 24,
      );

      _drawText(
        canvas,
        target.label,
        Offset(animatedRect.left + 54, animatedRect.top + 13),
        fontSize: 12.5,
        color: Colors.white,
        fontWeight: FontWeight.w800,
        maxWidth: animatedRect.width - 64,
        maxLines: 2,
      );
      _drawText(
        canvas,
        isSelected ? 'SELECTED' : 'TAP TO INSPECT',
        Offset(animatedRect.left + 54, animatedRect.bottom - 20),
        fontSize: 8.5,
        color: isSelected ? Colors.white : Colors.white60,
        fontWeight: FontWeight.w900,
        maxWidth: animatedRect.width - 64,
      );
    }
  }

  Rect _targetRectFor(int index, int count) {
    final safeWidth = math.max(300.0, size.x);
    final safeHeight = math.max(300.0, size.y);
    final horizontalPadding = 18.0;
    final gap = 10.0;
    final cardWidth = (safeWidth - horizontalPadding * 2 - gap) / 2;
    final rows = (count / 2).ceil();
    final availableHeight = math.max(150.0, safeHeight - 120);
    final cardHeight = math.min(72.0, (availableHeight - (rows - 1) * gap) / rows);
    final row = index ~/ 2;
    final column = index % 2;
    final isLastOdd = count.isOdd && index == count - 1;
    final left = isLastOdd
        ? (safeWidth - cardWidth) / 2
        : horizontalPadding + column * (cardWidth + gap);
    final top = 84.0 + row * (cardHeight + gap);
    return Rect.fromLTWH(left, top, cardWidth, cardHeight);
  }

  void _drawTapBursts(Canvas canvas) {
    for (final burst in _tapBursts) {
      final progress = (burst.age / burst.duration).clamp(0.0, 1.0).toDouble();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - progress)
        ..color = burst.color.withOpacity((1 - progress) * 0.72);
      canvas.drawCircle(burst.center, 12 + progress * 48, paint);
    }
  }

  String _iconFor(FlameMiniGameTargetModel target) {
    switch (definition.kind) {
      case FlameMiniGameKind.bugHuntRoom:
        return target.isCorrect ? '!' : '?';
      case FlameMiniGameKind.dataCleanupRace:
        return target.isCorrect ? '✓' : '•';
      case FlameMiniGameKind.blueprintSafetyPuzzle:
        return target.isCorrect ? '!' : '✓';
    }
  }

  void _drawHud(Canvas canvas) {
    final selectedCount = selectedTargetIds.value.length;
    final remaining = remainingSeconds.value;
    final warning = remaining <= 10;
    final timerColor = warning
        ? Color.lerp(
            const Color(0xFFFFD166),
            const Color(0xFFFF4D6D),
            (math.sin(_visualTime * 6) + 1) / 2,
          )!
        : Colors.white;

    _drawText(
      canvas,
      'LIVE INCIDENT',
      const Offset(18, 13),
      fontSize: 9,
      color: _accentColor,
      fontWeight: FontWeight.w900,
      maxWidth: 120,
    );
    _drawText(
      canvas,
      definition.title,
      const Offset(18, 29),
      fontSize: 19,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      maxWidth: math.max(120.0, size.x - 145),
    );
    _drawText(
      canvas,
      '${remaining}s',
      Offset(size.x - 72, 22),
      fontSize: 22,
      color: timerColor,
      fontWeight: FontWeight.w900,
      maxWidth: 56,
      textAlign: TextAlign.right,
    );

    final progressWidth = math.max(60.0, size.x - 36);
    final progressFraction = definition.timeLimitSeconds <= 0
        ? 0.0
        : remaining / definition.timeLimitSeconds;
    final progressRect = Rect.fromLTWH(18, 60, progressWidth, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(progressRect, const Radius.circular(3)),
      Paint()..color = Colors.white.withOpacity(0.12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          progressRect.left,
          progressRect.top,
          progressRect.width * progressFraction.clamp(0.0, 1.0).toDouble(),
          progressRect.height,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = timerColor,
    );

    _drawText(
      canvas,
      'SELECTED $selectedCount  •  NEED ${definition.successThreshold}',
      Offset(18, size.y - 25),
      fontSize: 10,
      color: Colors.white70,
      fontWeight: FontWeight.w900,
      maxWidth: size.x - 36,
    );
  }

  void _drawVignette(Canvas canvas) {
    final rect = Offset.zero & Size(size.x, size.y);
    final paint = Paint()
      ..shader = RadialGradient(
        radius: 0.95,
        colors: <Color>[
          Colors.transparent,
          Colors.black.withOpacity(0.08),
          Colors.black.withOpacity(0.48),
        ],
        stops: const <double>[0.48, 0.76, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
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
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.12,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? math.max(80.0, size.x - 36));
    textPainter.paint(canvas, offset);
  }
}

class _TapBurst {
  _TapBurst({required this.center, required this.color});

  final Offset center;
  final Color color;
  final double duration = 0.55;
  double age = 0;
}

class _BackgroundParticle {
  const _BackgroundParticle({
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
