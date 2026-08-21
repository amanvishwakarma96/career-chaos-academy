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

/// Persistent Developer-role Flame hub.
///
/// Phase 36D upgrades the visual identity while remaining presentation-only:
/// scenario progression, scoring, XP, reputation, skill trees, and backend data
/// are unchanged.
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
      normalizedPosition: Offset(0.29, 0.37),
      symbol: '</>',
    ),
    HubWorldLocation(
      kind: HubWorldLocationKind.bugHuntRoom,
      label: 'Bug Hunt Lab',
      subtitle: 'Live debugging challenge',
      normalizedPosition: Offset(0.73, 0.62),
      symbol: '!',
    ),
  ];

  static const Offset _spawnPosition = Offset(0.17, 0.82);
  static const double _walkSpeed = 0.46;

  Offset _playerPosition = _spawnPosition;
  HubWorldLocation? _pendingLocation;
  bool _reducedMotion;
  double _motionClock = 0;
  double _idleClock = 0;

  bool get isWalking => _pendingLocation != null;

  @override
  Color backgroundColor() => const Color(0xFF04060D);

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
    if (!_reducedMotion) {
      _idleClock += dt;
    }

    final pending = _pendingLocation;
    if (pending == null || _reducedMotion) {
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

    _drawAtmosphere(canvas, bounds);
    _drawSkyline(canvas);
    _drawFloorPlane(canvas);
    _drawProductionOffice(canvas);
    _drawBugLab(canvas);
    _drawCampusPath(canvas);
    _drawAmbientProps(canvas);

    for (final location in locations) {
      _drawLocationInteraction(canvas, location);
    }

    _drawPlayer(canvas);
    _drawHeader(canvas);
    _drawVignette(canvas, bounds);
  }

  void _drawAtmosphere(Canvas canvas, Rect bounds) {
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

    final pulse = _reducedMotion ? 1.0 : 0.90 + math.sin(_idleClock * 1.3) * 0.10;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.25),
          radius: 0.95,
          colors: <Color>[
            const Color(0xFF2E7DFF).withValues(alpha: 0.16 * pulse),
            Colors.transparent,
          ],
        ).createShader(bounds),
    );
  }

  void _drawSkyline(Canvas canvas) {
    final horizon = size.y * 0.43;
    final farPaint = Paint()..color = const Color(0xFF0A0E19);
    final midPaint = Paint()..color = const Color(0xFF0E1422);

    for (var i = 0; i < 9; i += 1) {
      final width = size.x * (0.07 + (i % 3) * 0.012);
      final height = size.y * (0.10 + (i % 4) * 0.035);
      final left = i * size.x / 8.2 - width * 0.4;
      final rect = Rect.fromLTWH(left, horizon - height, width, height);
      canvas.drawRect(rect, i.isEven ? farPaint : midPaint);

      final windowPaint = Paint()
        ..color = (i % 3 == 0 ? const Color(0xFF70D6FF) : const Color(0xFFFFC857))
            .withValues(alpha: 0.18);
      for (double y = rect.top + 12; y < rect.bottom - 8; y += 17) {
        for (double x = rect.left + 9; x < rect.right - 8; x += 16) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, 7, 4),
              const Radius.circular(1.5),
            ),
            windowPaint,
          );
        }
      }
    }
  }

  void _drawFloorPlane(Canvas canvas) {
    final top = size.y * 0.40;
    final floor = Path()
      ..moveTo(0, top)
      ..lineTo(size.x, top)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(
      floor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF111725).withValues(alpha: 0.94),
            const Color(0xFF070A11),
          ],
        ).createShader(Rect.fromLTWH(0, top, size.x, size.y - top)),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFF70D6FF).withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i += 1) {
      final t = i / 8;
      final y = top + (size.y - top) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }
    for (var i = -6; i <= 6; i += 1) {
      final startX = size.x * 0.5 + i * 24;
      final endX = size.x * 0.5 + i * size.x * 0.12;
      canvas.drawLine(Offset(startX, top), Offset(endX, size.y), gridPaint);
    }
  }

  void _drawProductionOffice(Canvas canvas) {
    final rect = _locationRect(locations.first);
    final building = Rect.fromLTWH(
      rect.left - 18,
      rect.top - 54,
      rect.width + 36,
      rect.height + 58,
    );
    final accent = const Color(0xFF70D6FF);

    canvas.drawRRect(
      RRect.fromRectAndRadius(building, const Radius.circular(22)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF1B2B46),
            const Color(0xFF0B101B),
          ],
        ).createShader(building),
    );

    final glass = Rect.fromLTWH(
      building.left + 14,
      building.top + 16,
      building.width - 28,
      48,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glass, const Radius.circular(10)),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.24),
            const Color(0xFF14243A).withValues(alpha: 0.82),
          ],
        ).createShader(glass),
    );

    final deskY = building.bottom - 35;
    canvas.drawRect(
      Rect.fromLTWH(building.left + 20, deskY, building.width - 40, 7),
      Paint()..color = const Color(0xFF26344A),
    );
    for (var i = 0; i < 3; i += 1) {
      final monitor = Rect.fromLTWH(
        building.left + 28 + i * ((building.width - 76) / 3),
        deskY - 25,
        30,
        19,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(monitor, const Radius.circular(4)),
        Paint()..color = const Color(0xFF0B1220),
      );
      canvas.drawRect(
        monitor.deflate(4),
        Paint()..color = accent.withValues(alpha: 0.55),
      );
    }

    _drawText(
      canvas,
      'PRODUCTION',
      Offset(building.left + 18, building.top + 76),
      fontSize: 9,
      color: accent.withValues(alpha: 0.85),
      fontWeight: FontWeight.w900,
      maxWidth: building.width - 36,
    );
  }

  void _drawBugLab(Canvas canvas) {
    final rect = _locationRect(locations.last);
    final building = Rect.fromLTWH(
      rect.left - 16,
      rect.top - 46,
      rect.width + 32,
      rect.height + 52,
    );
    final accent = const Color(0xFFFF4D8D);

    canvas.drawRRect(
      RRect.fromRectAndRadius(building, const Radius.circular(28)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF33152B),
            const Color(0xFF0D0B14),
          ],
        ).createShader(building),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(building, const Radius.circular(28)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent.withValues(alpha: 0.42),
    );

    final screen = Rect.fromLTWH(
      building.left + 20,
      building.top + 18,
      building.width - 40,
      50,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(screen, const Radius.circular(9)),
      Paint()..color = const Color(0xFF090811),
    );
    final scan = _reducedMotion ? 0.5 : (math.sin(_idleClock * 2.4) + 1) / 2;
    canvas.drawRect(
      Rect.fromLTWH(
        screen.left + 8,
        screen.top + 8 + scan * (screen.height - 18),
        screen.width - 16,
        2,
      ),
      Paint()..color = accent.withValues(alpha: 0.62),
    );
    _drawText(
      canvas,
      'INCIDENT FEED',
      Offset(building.left + 20, building.top + 78),
      fontSize: 9,
      color: accent.withValues(alpha: 0.90),
      fontWeight: FontWeight.w900,
      maxWidth: building.width - 40,
    );
  }

  void _drawCampusPath(Canvas canvas) {
    final start = _locationRect(locations.first).center;
    final end = _locationRect(locations.last).center;
    final spawn = Offset(size.x * _spawnPosition.dx, size.y * _spawnPosition.dy);
    final path = Path()
      ..moveTo(spawn.dx, spawn.dy)
      ..quadraticBezierTo(size.x * 0.30, size.y * 0.72, start.dx, start.dy + 48)
      ..quadraticBezierTo(size.x * 0.49, size.y * 0.52, end.dx, end.dy + 48);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.34),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF56F2C3).withValues(alpha: 0.20),
    );
  }

  void _drawAmbientProps(Canvas canvas) {
    final accent = const Color(0xFF56F2C3);
    final rackX = size.x * 0.50;
    final rackY = size.y * 0.60;
    for (var i = 0; i < 3; i += 1) {
      final rack = Rect.fromLTWH(rackX + i * 24, rackY + i * 8, 18, 52);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rack, const Radius.circular(4)),
        Paint()..color = const Color(0xFF111A25),
      );
      for (var led = 0; led < 4; led += 1) {
        canvas.drawCircle(
          Offset(rack.left + 6, rack.top + 10 + led * 10),
          1.8,
          Paint()
            ..color = (led.isEven ? accent : const Color(0xFFFFC857))
                .withValues(alpha: 0.70),
        );
      }
    }
  }

  Rect _locationRect(HubWorldLocation location) {
    final width = math.min(230.0, math.max(150.0, size.x * 0.34));
    final height = math.min(116.0, math.max(94.0, size.y * 0.18));
    final center = Offset(
      size.x * location.normalizedPosition.dx,
      size.y * location.normalizedPosition.dy,
    );
    final maxLeft = math.max(14.0, size.x - width - 14);
    final maxTop = math.max(86.0, size.y - height - 30);
    final left = (center.dx - width / 2).clamp(14.0, maxLeft).toDouble();
    final top = (center.dy - height / 2).clamp(86.0, maxTop).toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  Offset _walkTargetFor(HubWorldLocation location) {
    final rect = _locationRect(location);
    final target = Offset(rect.center.dx, rect.bottom + 34);
    return Offset(
      (target.dx / math.max(1.0, size.x)).clamp(0.08, 0.92).toDouble(),
      (target.dy / math.max(1.0, size.y)).clamp(0.16, 0.91).toDouble(),
    );
  }

  void _drawLocationInteraction(Canvas canvas, HubWorldLocation location) {
    final rect = _locationRect(location);
    final accent = location.kind == HubWorldLocationKind.chapterOne
        ? const Color(0xFF70D6FF)
        : const Color(0xFFFF4D8D);
    final selected = _pendingLocation?.kind == location.kind;
    final plate = Rect.fromLTWH(rect.left + 8, rect.bottom - 38, rect.width - 16, 32);

    if (selected && !_reducedMotion) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          plate.inflate(6 + math.sin(_motionClock * 8).abs() * 2),
          const Radius.circular(16),
        ),
        Paint()..color = accent.withValues(alpha: 0.10),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, const Radius.circular(12)),
      Paint()..color = const Color(0xFF060811).withValues(alpha: 0.88),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.8 : 1.0
        ..color = accent.withValues(alpha: selected ? 0.92 : 0.50),
    );

    _drawText(
      canvas,
      '${location.symbol}  ${location.label}',
      Offset(plate.left + 10, plate.top + 5),
      fontSize: 10.5,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      maxWidth: plate.width - 20,
    );
    _drawText(
      canvas,
      selected ? 'APPROACHING…' : 'TAP TO ENTER',
      Offset(plate.left + 10, plate.top + 18),
      fontSize: 7.5,
      color: accent,
      fontWeight: FontWeight.w900,
      maxWidth: plate.width - 20,
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
            ? math.sin(_motionClock * 15) * 2.1
            : math.sin(_idleClock * 2.7) * 1.5;
    final stride = moving ? math.sin(_motionClock * 17) : 0.0;
    final center = base.translate(0, bob);

    canvas.drawOval(
      Rect.fromCenter(center: base.translate(0, 29), width: 48, height: 13),
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );

    final glow = _reducedMotion ? 0.16 : 0.14 + (math.sin(_idleClock * 2) + 1) * 0.03;
    canvas.drawCircle(
      center.translate(0, -1),
      31,
      Paint()..color = const Color(0xFF56F2C3).withValues(alpha: glow),
    );

    final legPaint = Paint()
      ..color = const Color(0xFF202A3A)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center.translate(-6, 10),
      center.translate(-8 + stride * 5, 28),
      legPaint,
    );
    canvas.drawLine(
      center.translate(6, 10),
      center.translate(8 - stride * 5, 28),
      legPaint,
    );

    final torso = Rect.fromCenter(center: center.translate(0, 2), width: 28, height: 30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(torso, const Radius.circular(9)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF56F2C3), Color(0xFF1BA98A)],
        ).createShader(torso),
    );

    final armPaint = Paint()
      ..color = const Color(0xFF39C9A8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center.translate(-12, -2),
      center.translate(-17 - stride * 3, 10),
      armPaint,
    );
    canvas.drawLine(
      center.translate(12, -2),
      center.translate(17 + stride * 3, 10),
      armPaint,
    );

    canvas.drawCircle(
      center.translate(0, -17),
      10,
      Paint()..color = const Color(0xFFFFD8B7),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(0, -19), radius: 10),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF182033),
    );

    final laptop = Rect.fromLTWH(center.dx - 9, center.dy - 1, 18, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(laptop, const Radius.circular(3)),
      Paint()..color = const Color(0xFF0C1320),
    );
    _drawText(
      canvas,
      '</>',
      Offset(laptop.left + 2, laptop.top + 2),
      fontSize: 6,
      color: const Color(0xFF70D6FF),
      fontWeight: FontWeight.w900,
      maxWidth: 14,
      textAlign: TextAlign.center,
    );

    _drawText(
      canvas,
      moving ? 'MOVING' : 'DEV',
      base.translate(-26, 35),
      fontSize: 8,
      color: const Color(0xFF56F2C3),
      fontWeight: FontWeight.w900,
      maxWidth: 52,
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
      'Production never sleeps.',
      const Offset(20, 38),
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.w900,
      maxWidth: math.max(180.0, size.x - 40),
    );
    _drawText(
      canvas,
      'Pick the next fire to put out.',
      const Offset(20, 64),
      fontSize: 10,
      color: Colors.white60,
      fontWeight: FontWeight.w600,
      maxWidth: math.max(180.0, size.x - 40),
    );
  }

  void _drawVignette(Canvas canvas, Rect bounds) {
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          radius: 0.98,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.58),
          ],
          stops: const <double>[0.46, 0.78, 1],
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
