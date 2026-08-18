import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Locations exposed by the Developer hub vertical slice.
enum HubWorldLocationKind {
  chapterOne,
  bugHuntRoom,
}

class HubWorldLocation {
  const HubWorldLocation({
    required this.kind,
    required this.label,
    required this.subtitle,
    required this.normalizedPosition,
    required this.symbol,
  });

  final HubWorldLocationKind kind;
  final String label;
  final String subtitle;
  final Offset normalizedPosition;
  final String symbol;
}

typedef HubWorldLocationSelected = void Function(HubWorldLocationKind kind);

/// Small persistent Flame canvas used as the Developer role entry point.
///
/// Phase 36B intentionally keeps this presentation-only: it does not change
/// scenario progression, scoring, XP, reputation, skill trees, or backend data.
class HubWorldGame extends FlameGame with TapCallbacks {
  HubWorldGame({
    required this.onLocationSelected,
    bool reducedMotion = false,
  }) : _reducedMotion = reducedMotion;

  final HubWorldLocationSelected onLocationSelected;
  final ValueNotifier<String> statusMessage = ValueNotifier<String>(
    'Tap a location and your Developer will walk there.',
  );

  static const List<HubWorldLocation> locations = <HubWorldLocation>[
    HubWorldLocation(
      kind: HubWorldLocationKind.chapterOne,
      label: 'Production Office',
      subtitle: 'Chapter 1 • Login Button Disaster',
      normalizedPosition: Offset(0.30, 0.34),
      symbol: '</>',
    ),
    HubWorldLocation(
      kind: HubWorldLocationKind.bugHuntRoom,
      label: 'Bug Hunt Lab',
      subtitle: 'Live debugging challenge',
      normalizedPosition: Offset(0.72, 0.64),
      symbol: '!',
    ),
  ];

  static const Offset _spawnPosition = Offset(0.18, 0.80);
  static const double _walkSpeed = 0.46;

  Offset _playerPosition = _spawnPosition;
  HubWorldLocation? _pendingLocation;
  bool _reducedMotion;
  double _motionClock = 0;
  double _idleClock = 0;

  bool get isWalking => _pendingLocation != null;

  @override
  Color backgroundColor() => const Color(0xFF060812);

  void setReducedMotion(bool value) {
    if (_reducedMotion == value) {
      return;
    }
    _reducedMotion = value;

    final pending = _pendingLocation;
    if (value && pending != null) {
      _playerPosition = _walkTargetFor(pending);
      _pendingLocation = null;
      statusMessage.value = 'Entering ${pending.label}…';
      onLocationSelected(pending.kind);
    }
  }

  void markHubReady() {
    statusMessage.value = _reducedMotion
        ? 'Tap a location to enter instantly. Reduced motion is on.'
        : 'Tap a location and your Developer will walk there.';
  }

  void disposeNotifiers() {
    statusMessage.dispose();
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tap = event.localPosition.toOffset();
    for (final location in locations) {
      if (_locationRect(location).inflate(10).contains(tap)) {
        _moveToLocation(location);
        return;
      }
    }
  }

  void _moveToLocation(HubWorldLocation location) {
    if (_pendingLocation != null) {
      return;
    }

    if (_reducedMotion) {
      _playerPosition = _walkTargetFor(location);
      statusMessage.value = 'Entering ${location.label}…';
      onLocationSelected(location.kind);
      return;
    }

    _pendingLocation = location;
    _motionClock = 0;
    statusMessage.value = 'Walking to ${location.label}…';
  }

  @override
  void update(double dt) {
    super.update(dt);
    final pending = _pendingLocation;
    if (pending == null) {
      if (!_reducedMotion) {
        _idleClock += dt;
      }
      return;
    }

    if (_reducedMotion) {
      return;
    }

    _motionClock += dt;
    final target = _walkTargetFor(pending);
    final delta = target - _playerPosition;
    final distance = delta.distance;
    final step = _walkSpeed * dt;

    if (distance <= step || distance < 0.002) {
      _playerPosition = target;
      _pendingLocation = null;
      statusMessage.value = 'Entering ${pending.label}…';
      onLocationSelected(pending.kind);
      return;
    }

    _playerPosition += delta / distance * step;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final bounds = Offset.zero & Size(size.x, size.y);

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF071225),
          Color(0xFF16132C),
          Color(0xFF080A13),
        ],
      ).createShader(bounds);
    canvas.drawRect(bounds, background);

    _drawGrid(canvas);
    _drawCampusPath(canvas);
    _drawAmbientZones(canvas);
    for (final location in locations) {
      _drawLocation(canvas, location);
    }
    _drawPlayer(canvas);
    _drawHeader(canvas);
    _drawVignette(canvas, bounds);
  }

  void _drawGrid(Canvas canvas) {
    const spacing = 36.0;
    final paint = Paint()
      ..color = const Color(0xFF70D6FF).withOpacity(0.045)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.x; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), paint);
    }
    for (double y = 0; y <= size.y; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), paint);
    }
  }

  void _drawCampusPath(Canvas canvas) {
    if (locations.length < 2) {
      return;
    }
    final start = _locationRect(locations.first).center;
    final end = _locationRect(locations.last).center;
    final path = Path()
      ..moveTo(size.x * _spawnPosition.dx, size.y * _spawnPosition.dy)
      ..quadraticBezierTo(size.x * 0.36, size.y * 0.68, start.dx, start.dy)
      ..quadraticBezierTo(size.x * 0.50, size.y * 0.48, end.dx, end.dy);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.035),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFF4D8D).withOpacity(0.28),
    );
  }

  void _drawAmbientZones(Canvas canvas) {
    final pulse = _reducedMotion ? 1.0 : 0.88 + (math.sin(_idleClock * 1.6) * 0.12);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFFF4D8D).withOpacity(0.10 * pulse),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.x * 0.35, size.y * 0.40),
          radius: math.min(size.x, size.y) * 0.42,
        ),
      );
    canvas.drawRect(Offset.zero & Size(size.x, size.y), glowPaint);
  }

  Rect _locationRect(HubWorldLocation location) {
    final width = math.min(230.0, math.max(145.0, size.x * 0.34));
    final height = math.min(118.0, math.max(96.0, size.y * 0.20));
    final center = Offset(
      size.x * location.normalizedPosition.dx,
      size.y * location.normalizedPosition.dy,
    );
    final maxLeft = math.max(14.0, size.x - width - 14);
    final maxTop = math.max(82.0, size.y - height - 24);
    final left = (center.dx - width / 2).clamp(14.0, maxLeft).toDouble();
    final top = (center.dy - height / 2).clamp(82.0, maxTop).toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  Offset _walkTargetFor(HubWorldLocation location) {
    final rect = _locationRect(location);
    final target = Offset(rect.center.dx, rect.bottom + 30);
    return Offset(
      (target.dx / math.max(1.0, size.x)).clamp(0.08, 0.92).toDouble(),
      (target.dy / math.max(1.0, size.y)).clamp(0.16, 0.90).toDouble(),
    );
  }

  void _drawLocation(Canvas canvas, HubWorldLocation location) {
    final rect = _locationRect(location);
    final accent = location.kind == HubWorldLocationKind.chapterOne
        ? const Color(0xFF70D6FF)
        : const Color(0xFFFF4D8D);
    final selected = _pendingLocation?.kind == location.kind;

    if (selected && !_reducedMotion) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(8 + math.sin(_motionClock * 8).abs() * 3),
          const Radius.circular(28),
        ),
        Paint()..color = accent.withOpacity(0.10),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 7)),
        const Radius.circular(22),
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withOpacity(selected ? 0.46 : 0.34),
            const Color(0xFF121625).withOpacity(0.96),
          ],
        ).createShader(rect),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.2 : 1.5
        ..color = accent.withOpacity(selected ? 0.95 : 0.70),
    );

    final iconCenter = Offset(rect.left + 34, rect.center.dy);
    canvas.drawCircle(
      iconCenter,
      20,
      Paint()..color = accent.withOpacity(0.22),
    );
    _drawText(
      canvas,
      location.symbol,
      iconCenter.translate(-13, -12),
      fontSize: 15,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      maxWidth: 26,
      textAlign: TextAlign.center,
    );

    _drawText(
      canvas,
      location.label,
      Offset(rect.left + 64, rect.top + 22),
      fontSize: 15,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      maxWidth: rect.width - 76,
    );
    _drawText(
      canvas,
      location.subtitle,
      Offset(rect.left + 64, rect.top + 48),
      fontSize: 10,
      color: Colors.white70,
      fontWeight: FontWeight.w600,
      maxWidth: rect.width - 76,
    );
    _drawText(
      canvas,
      selected ? 'APPROACHING…' : 'TAP TO ENTER',
      Offset(rect.left + 64, rect.bottom - 24),
      fontSize: 8.5,
      color: accent,
      fontWeight: FontWeight.w900,
      maxWidth: rect.width - 76,
    );
  }

  void _drawPlayer(Canvas canvas) {
    final base = Offset(
      size.x * _playerPosition.dx,
      size.y * _playerPosition.dy,
    );
    final moving = isWalking && !_reducedMotion;
    final bob = _reducedMotion
        ? 0.0
        : moving
            ? math.sin(_motionClock * 15) * 2.2
            : math.sin(_idleClock * 3.0) * 1.8;
    final stride = moving ? math.sin(_motionClock * 17) * 5.0 : 0.0;
    final center = base.translate(0, bob);

    canvas.drawOval(
      Rect.fromCenter(
        center: base.translate(0, 22),
        width: 42,
        height: 13,
      ),
      Paint()..color = Colors.black.withOpacity(0.36),
    );

    canvas.drawCircle(
      center,
      26,
      Paint()..color = const Color(0xFF56F2C3).withOpacity(0.12),
    );

    final limbPaint = Paint()
      ..color = const Color(0xFF56F2C3)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center.translate(-5, 9),
      center.translate(-7 + stride, 24),
      limbPaint,
    );
    canvas.drawLine(
      center.translate(5, 9),
      center.translate(7 - stride, 24),
      limbPaint,
    );
    canvas.drawLine(
      center.translate(-8, -1),
      center.translate(-15 - stride * 0.45, 8),
      limbPaint,
    );
    canvas.drawLine(
      center.translate(8, -1),
      center.translate(15 + stride * 0.45, 8),
      limbPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 4), width: 22, height: 25),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF56F2C3),
    );
    canvas.drawCircle(
      center.translate(0, -12),
      9,
      Paint()..color = const Color(0xFF8BFFE0),
    );
    canvas.drawCircle(
      center.translate(0, -13),
      4,
      Paint()..color = const Color(0xFF071D1B),
    );

    _drawText(
      canvas,
      moving ? 'WALKING' : 'YOU',
      base.translate(-28, 31),
      fontSize: 8,
      color: const Color(0xFF56F2C3),
      fontWeight: FontWeight.w900,
      maxWidth: 56,
      textAlign: TextAlign.center,
    );
  }

  void _drawHeader(Canvas canvas) {
    _drawText(
      canvas,
      'DEVELOPER DISTRICT',
      const Offset(20, 18),
      fontSize: 10,
      color: const Color(0xFFFF80AD),
      fontWeight: FontWeight.w900,
      maxWidth: math.max(120.0, size.x - 40),
    );
    _drawText(
      canvas,
      'Walk into the next problem.',
      const Offset(20, 38),
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      maxWidth: math.max(180.0, size.x - 40),
    );
  }

  void _drawVignette(Canvas canvas, Rect bounds) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withOpacity(0.08),
            Colors.black.withOpacity(0.52),
          ],
          stops: const <double>[0.48, 0.78, 1],
        ).createShader(bounds),
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
          height: 1.12,
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
