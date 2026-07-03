import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/game_visual_settings_model.dart';
import '../services/game_visual_settings_service.dart';
import '../services/animation_service.dart';

class CinematicAtmosphereGame extends FlameGame {
  CinematicAtmosphereGame({
    String sceneKey = 'scene',
    String emotion = 'neutral',
  })  : _sceneKey = sceneKey,
        _emotion = emotion;

  String _sceneKey;
  String _emotion;
  double _elapsed = 0;

  final List<_AmbientParticle> _particles = <_AmbientParticle>[];
  final math.Random _random = math.Random(36);

  GameVisualQuality get _quality =>
      GameVisualSettingsService.instance.currentQuality;
  double get _visualTime =>
      AnimationService.instance.isReducedMotion ? 0 : _elapsed;

  @override
  Color backgroundColor() => const Color(0x00000000);

  void updateMood({required String sceneKey, required String emotion}) {
    _sceneKey = sceneKey;
    _emotion = emotion;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _rebuildParticles();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_particles.isEmpty) {
      _rebuildParticles();
    }
  }

  void _rebuildParticles() {
    _particles.clear();
    final budget = _quality.particleBudget;
    for (var index = 0; index < budget; index += 1) {
      _particles.add(
        _AmbientParticle(
          seedX: _random.nextDouble(),
          seedY: _random.nextDouble(),
          radius: 0.8 + (_random.nextDouble() * 2.8),
          speed: 4 + (_random.nextDouble() * 12),
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_particles.length != _quality.particleBudget) {
      _rebuildParticles();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    _drawAmbientParticles(canvas);
    if (_quality.usesAmbientEffects) {
      _drawLightBeams(canvas);
      _drawScanlines(canvas);
    }
    if (_quality.usesHeavyEffects) {
      _drawTensionPulse(canvas);
    }
    _drawVignette(canvas);
  }

  void _drawAmbientParticles(Canvas canvas) {
    final tone = _toneForEmotion(_emotion);
    final sceneOffset = _sceneKey.hashCode.abs() % 31;
    for (var index = 0; index < _particles.length; index += 1) {
      final particle = _particles[index];
      final driftX = math.sin(_visualTime * 0.55 + particle.phase) * 18;
      final travel = (_visualTime * particle.speed + particle.seedY * size.y + sceneOffset * index) %
          math.max(1.0, size.y + 80);
      final x = particle.seedX * size.x + driftX;
      final y = size.y + 30 - travel;
      final opacity = 0.08 +
          (math.sin(_visualTime * 1.2 + particle.phase) + 1) * 0.06;
      final paint = Paint()
        ..color = tone.withOpacity(opacity.clamp(0.04, 0.24).toDouble())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), particle.radius, paint);
    }
  }

  void _drawLightBeams(Canvas canvas) {
    final tone = _toneForEmotion(_emotion);
    final pulse = (math.sin(_visualTime * 0.7) + 1) / 2;
    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          tone.withOpacity(0.02),
          tone.withOpacity(0.10 + pulse * 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y))
      ..blendMode = BlendMode.screen;

    final path = Path()
      ..moveTo(size.x * 0.12, 0)
      ..lineTo(size.x * 0.52, 0)
      ..lineTo(size.x * 0.78, size.y)
      ..lineTo(size.x * 0.34, size.y)
      ..close();
    canvas.drawPath(path, beamPaint);
  }

  void _drawScanlines(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 1;
    final offset = (_visualTime * 12) % 6;
    for (double y = -6 + offset; y < size.y; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }

  void _drawTensionPulse(Canvas canvas) {
    final tone = _toneForEmotion(_emotion);
    final pulse = (math.sin(_visualTime * 2.1) + 1) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = tone.withOpacity(0.04 + pulse * 0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(
      Offset(size.x * 0.52, size.y * 0.48),
      90 + pulse * 50,
      paint,
    );
  }

  void _drawVignette(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..shader = RadialGradient(
        radius: 0.88,
        colors: <Color>[
          Colors.transparent,
          Colors.black.withOpacity(0.12),
          Colors.black.withOpacity(0.52),
        ],
        stops: const <double>[0.45, 0.76, 1],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  Color _toneForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'angry':
      case 'panic':
      case 'tense':
        return const Color(0xFFFF5D5D);
      case 'worried':
      case 'concerned':
        return const Color(0xFFFFC857);
      case 'focused':
      case 'serious':
        return const Color(0xFF70D6FF);
      case 'calm':
      case 'confident':
        return const Color(0xFF72F1B8);
      default:
        return const Color(0xFFC77DFF);
    }
  }
}

class _AmbientParticle {
  const _AmbientParticle({
    required this.seedX,
    required this.seedY,
    required this.radius,
    required this.speed,
    required this.phase,
  });

  final double seedX;
  final double seedY;
  final double radius;
  final double speed;
  final double phase;
}
