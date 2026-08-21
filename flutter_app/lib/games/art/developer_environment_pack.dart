import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Authored vector environment layers for the Developer hub.
///
/// Keeps background/foreground art separate from gameplay so bitmap art can
/// replace these layers later without changing navigation or scoring code.
class DeveloperEnvironmentPack {
  const DeveloperEnvironmentPack();

  void renderBackground(
    Canvas canvas, {
    required Size size,
    required double time,
    required bool reducedMotion,
  }) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF071325),
            Color(0xFF11142B),
            Color(0xFF05070E),
          ],
          stops: <double>[0, 0.56, 1],
        ).createShader(bounds),
    );

    final drift = reducedMotion ? 0.0 : math.sin(time * 0.22) * 12;
    _drawFarSkyline(canvas, size, drift);
    _drawNearSkyline(canvas, size, -drift * 0.42);
    _drawFloor(canvas, size);
    _drawAmbientLight(canvas, size, time, reducedMotion);
  }

  void renderForeground(
    Canvas canvas, {
    required Size size,
    required double time,
    required bool reducedMotion,
  }) {
    final sway = reducedMotion ? 0.0 : math.sin(time * 0.7) * 1.8;
    _drawCableBundle(canvas, size, sway);
    _drawForegroundConsole(canvas, size);
  }

  void _drawFarSkyline(Canvas canvas, Size size, double offset) {
    final horizon = size.height * 0.40;
    for (var i = 0; i < 11; i += 1) {
      final width = size.width * (0.055 + (i % 3) * 0.012);
      final height = size.height * (0.09 + (i % 4) * 0.026);
      final left = i * size.width / 9.6 - width * 0.5 + offset;
      final rect = Rect.fromLTWH(left, horizon - height, width, height);
      canvas.drawRect(rect, Paint()..color = const Color(0xFF080D16));
      final windows = Paint()..color = const Color(0xFF70D6FF).withValues(alpha: 0.11);
      for (double y = rect.top + 10; y < rect.bottom - 6; y += 15) {
        for (double x = rect.left + 8; x < rect.right - 6; x += 14) {
          canvas.drawRect(Rect.fromLTWH(x, y, 5, 3), windows);
        }
      }
    }
  }

  void _drawNearSkyline(Canvas canvas, Size size, double offset) {
    final horizon = size.height * 0.43;
    for (var i = 0; i < 6; i += 1) {
      final width = size.width * (0.09 + (i % 2) * 0.025);
      final height = size.height * (0.12 + (i % 3) * 0.035);
      final left = i * size.width / 5.1 - width * 0.35 + offset;
      final rect = Rect.fromLTWH(left, horizon - height, width, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = const Color(0xFF0D1422),
      );
    }
  }

  void _drawFloor(Canvas canvas, Size size) {
    final top = size.height * 0.40;
    final rect = Rect.fromLTWH(0, top, size.width, size.height - top);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF111725), Color(0xFF070A11)],
        ).createShader(rect),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFF70D6FF).withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i += 1) {
      final t = i / 8;
      final y = top + (size.height - top) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = -6; i <= 6; i += 1) {
      final startX = size.width * 0.5 + i * 24;
      final endX = size.width * 0.5 + i * size.width * 0.12;
      canvas.drawLine(Offset(startX, top), Offset(endX, size.height), gridPaint);
    }
  }

  void _drawAmbientLight(Canvas canvas, Size size, double time, bool reducedMotion) {
    final pulse = reducedMotion ? 1.0 : 0.9 + math.sin(time * 1.2) * 0.1;
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.25),
          radius: 0.95,
          colors: <Color>[
            const Color(0xFF2E7DFF).withValues(alpha: 0.15 * pulse),
            Colors.transparent,
          ],
        ).createShader(bounds),
    );
  }

  void _drawCableBundle(Canvas canvas, Size size, double sway) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF151C29).withValues(alpha: 0.92);
    for (var i = 0; i < 3; i += 1) {
      final path = Path()
        ..moveTo(size.width - 22.0 - i * 7, size.height)
        ..cubicTo(
          size.width - 40.0 + sway,
          size.height * 0.84,
          size.width - 8.0 - sway,
          size.height * 0.72,
          size.width - 24.0 - i * 5,
          size.height * 0.58,
        );
      canvas.drawPath(path, paint);
    }
  }

  void _drawForegroundConsole(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(-22, size.height - 56, math.min(150, size.width * 0.34), 78);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      Paint()..color = const Color(0xFF080D15).withValues(alpha: 0.96),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(8), const Radius.circular(10)),
      Paint()..color = const Color(0xFF70D6FF).withValues(alpha: 0.055),
    );
  }
}
