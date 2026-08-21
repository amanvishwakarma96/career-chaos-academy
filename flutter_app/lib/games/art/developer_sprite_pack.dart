import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DeveloperSpriteState { idle, walk }

/// Authored vector sprite pack for the Developer vertical slice.
///
/// This is intentionally isolated from hub logic so it can later be replaced by
/// bitmap/sprite-sheet art without touching navigation or progression code.
class DeveloperSpritePack {
  const DeveloperSpritePack();

  static const Color _mint = Color(0xFF56F2C3);
  static const Color _mintDark = Color(0xFF1BA98A);
  static const Color _skin = Color(0xFFFFD8B7);
  static const Color _hair = Color(0xFF182033);
  static const Color _pants = Color(0xFF202A3A);
  static const Color _shoe = Color(0xFF0B1019);
  static const Color _cyan = Color(0xFF70D6FF);

  void render(
    Canvas canvas, {
    required Offset anchor,
    required DeveloperSpriteState state,
    required double motionTime,
    required double idleTime,
    required bool reducedMotion,
  }) {
    final walkFrame = reducedMotion || state == DeveloperSpriteState.idle
        ? 0
        : ((motionTime * 8).floor() % 4);
    final stride = const <double>[0, 1, 0, -1][walkFrame];
    final armSwing = const <double>[0, -1, 0, 1][walkFrame];
    final bob = reducedMotion
        ? 0.0
        : state == DeveloperSpriteState.walk
            ? const <double>[0, -1.8, 0, -1.0][walkFrame]
            : math.sin(idleTime * 2.6) * 1.2;
    final blink = !reducedMotion && state == DeveloperSpriteState.idle &&
        ((idleTime % 4.8) > 4.58);
    final center = anchor.translate(0, bob);

    _drawShadow(canvas, anchor, state == DeveloperSpriteState.walk ? 0.9 : 1.0);
    _drawAura(canvas, center, idleTime, reducedMotion);

    final legPaint = Paint()
      ..color = _pants
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center.translate(-6, 12), center.translate(-9 + stride * 5, 31), legPaint);
    canvas.drawLine(center.translate(6, 12), center.translate(9 - stride * 5, 31), legPaint);

    final shoePaint = Paint()
      ..color = _shoe
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center.translate(-9 + stride * 5, 31), center.translate(-13 + stride * 5, 32), shoePaint);
    canvas.drawLine(center.translate(9 - stride * 5, 31), center.translate(13 - stride * 5, 32), shoePaint);

    final torso = Rect.fromCenter(center: center.translate(0, 3), width: 30, height: 33);
    canvas.drawRRect(
      RRect.fromRectAndRadius(torso, const Radius.circular(10)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_mint, _mintDark],
        ).createShader(torso),
    );

    final hood = Path()
      ..moveTo(torso.left + 4, torso.top + 4)
      ..quadraticBezierTo(center.dx, torso.top - 6, torso.right - 4, torso.top + 4)
      ..lineTo(torso.right - 8, torso.top + 10)
      ..quadraticBezierTo(center.dx, torso.top + 2, torso.left + 8, torso.top + 10)
      ..close();
    canvas.drawPath(hood, Paint()..color = const Color(0xFF2BC7A7));

    final armPaint = Paint()
      ..color = const Color(0xFF39C9A8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center.translate(-13, -1), center.translate(-18 + armSwing * 4, 12), armPaint);
    canvas.drawLine(center.translate(13, -1), center.translate(18 - armSwing * 4, 12), armPaint);

    final head = center.translate(0, -18);
    canvas.drawCircle(head, 10.5, Paint()..color = _skin);
    canvas.drawArc(
      Rect.fromCircle(center: head.translate(0, -2), radius: 10.5),
      math.pi,
      math.pi,
      true,
      Paint()..color = _hair,
    );
    canvas.drawCircle(head.translate(-4, -1), 1.2, Paint()..color = _hair);
    if (!blink) {
      canvas.drawCircle(head.translate(4, -1), 1.2, Paint()..color = _hair);
    } else {
      canvas.drawLine(head.translate(2.5, -1), head.translate(5.5, -1), Paint()..color = _hair..strokeWidth = 1.2);
    }

    final laptop = Rect.fromLTWH(center.dx - 10, center.dy - 1, 20, 13);
    canvas.drawRRect(
      RRect.fromRectAndRadius(laptop, const Radius.circular(3)),
      Paint()..color = const Color(0xFF0C1320),
    );
    canvas.drawCircle(laptop.center, 2.1, Paint()..color = _cyan.withValues(alpha: 0.9));
  }

  void _drawShadow(Canvas canvas, Offset anchor, double scale) {
    canvas.drawOval(
      Rect.fromCenter(center: anchor.translate(0, 34), width: 52 * scale, height: 13),
      Paint()..color = Colors.black.withValues(alpha: 0.44),
    );
  }

  void _drawAura(Canvas canvas, Offset center, double idleTime, bool reducedMotion) {
    final alpha = reducedMotion ? 0.15 : 0.13 + (math.sin(idleTime * 2) + 1) * 0.025;
    canvas.drawCircle(center, 33, Paint()..color = _mint.withValues(alpha: alpha));
  }
}
