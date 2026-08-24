import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/animation_service.dart';

/// Presentation-only atmospheric layer for the persistent Developer district.
class DeveloperHubAtmosphereOverlay extends StatefulWidget {
  const DeveloperHubAtmosphereOverlay({
    super.key,
    required this.child,
    required this.status,
  });

  final Widget child;
  final ValueListenable<String> status;

  @override
  State<DeveloperHubAtmosphereOverlay> createState() =>
      _DeveloperHubAtmosphereOverlayState();
}

class _DeveloperHubAtmosphereOverlayState
    extends State<DeveloperHubAtmosphereOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _reducedMotion => AnimationService.instance.isReducedMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6400),
    );
    AnimationService.instance.reducedMotion.addListener(_handleMotionSetting);
    _syncMotion();
  }

  @override
  void dispose() {
    AnimationService.instance.reducedMotion.removeListener(_handleMotionSetting);
    _controller.dispose();
    super.dispose();
  }

  void _handleMotionSetting() {
    _syncMotion();
    if (mounted) {
      setState(() {});
    }
  }

  void _syncMotion() {
    if (_reducedMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _HubAtmospherePainter(
                  phase: _controller.value,
                  reducedMotion: _reducedMotion,
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 12,
          right: 14,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF050912).withValues(alpha: 0.80),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF56F2C3).withValues(alpha: 0.36),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 12,
                    color: Color(0xFF56F2C3),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'DISTRICT // ONLINE',
                    style: TextStyle(
                      color: Color(0xFF56F2C3),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 46,
          right: 14,
          child: IgnorePointer(
            child: ValueListenableBuilder<String>(
              valueListenable: widget.status,
              builder: (context, status, _) {
                final moving = status.toLowerCase().contains('walking');
                return AnimatedContainer(
                  duration: AnimationService.instance.duration(
                    const Duration(milliseconds: 220),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050912).withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: (moving
                              ? const Color(0xFFFFC857)
                              : const Color(0xFF70D6FF))
                          .withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    moving ? 'ROUTE LOCKED' : 'FREE ROAM',
                    style: TextStyle(
                      color: moving
                          ? const Color(0xFFFFC857)
                          : const Color(0xFF70D6FF),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HubAtmospherePainter extends CustomPainter {
  const _HubAtmospherePainter({
    required this.phase,
    required this.reducedMotion,
  });

  final double phase;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final movement = reducedMotion ? 0.0 : phase;

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.transparent,
          const Color(0xFF70D6FF).withValues(alpha: 0.035),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    for (var index = 0; index < 4; index += 1) {
      final x = ((index * 0.31 + movement * 0.18) % 1.25 - 0.12) * width;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + width * 0.12, height)
        ..lineTo(x + width * 0.18, height)
        ..lineTo(x + width * 0.04, 0)
        ..close();
      canvas.drawPath(path, beamPaint);
    }

    final particlePaint = Paint()
      ..color = const Color(0xFF56F2C3).withValues(alpha: 0.12);
    for (var index = 0; index < 12; index += 1) {
      final seed = index * 0.61803398875;
      final x = ((seed + movement * (0.025 + index % 3 * 0.008)) % 1) * width;
      final baseY = ((seed * 1.7 + index * 0.11) % 1) * height;
      final y = reducedMotion
          ? baseY
          : (baseY + math.sin(movement * math.pi * 2 + index) * 12);
      canvas.drawCircle(Offset(x, y), 1.1 + (index % 3) * 0.55, particlePaint);
    }

    final foreground = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Colors.black.withValues(alpha: 0.30),
          Colors.transparent,
          Colors.transparent,
          Colors.black.withValues(alpha: 0.34),
        ],
        stops: const <double>[0, 0.10, 0.88, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, foreground);
  }

  @override
  bool shouldRepaint(covariant _HubAtmospherePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}
