import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../games/base_mini_game.dart';
import '../services/animation_service.dart';

/// Presentation-only frame for live Developer simulations.
///
/// It reacts to the existing game notifiers, so it does not own gameplay,
/// scoring, progression, or persistence state. Reduced-motion users keep the
/// same information without shake/scan/pulse motion.
class DeveloperGameFeelFrame extends StatefulWidget {
  const DeveloperGameFeelFrame({
    super.key,
    required this.game,
    required this.child,
  });

  final BaseMiniGame game;
  final Widget child;

  @override
  State<DeveloperGameFeelFrame> createState() =>
      _DeveloperGameFeelFrameState();
}

class _DeveloperGameFeelFrameState extends State<DeveloperGameFeelFrame>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _impactController;
  String _lastFeedback = '';
  _FeedbackTone _impactTone = _FeedbackTone.neutral;

  bool get _reducedMotion => AnimationService.instance.isReducedMotion;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    );
    widget.game.feedbackMessage.addListener(_handleFeedback);
    AnimationService.instance.reducedMotion.addListener(_handleMotionSetting);
    _syncAmbientMotion();
  }

  @override
  void didUpdateWidget(covariant DeveloperGameFeelFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game == widget.game) {
      return;
    }
    oldWidget.game.feedbackMessage.removeListener(_handleFeedback);
    widget.game.feedbackMessage.addListener(_handleFeedback);
    _lastFeedback = '';
    _impactTone = _FeedbackTone.neutral;
    _impactController.reset();
  }

  @override
  void dispose() {
    widget.game.feedbackMessage.removeListener(_handleFeedback);
    AnimationService.instance.reducedMotion.removeListener(_handleMotionSetting);
    _ambientController.dispose();
    _impactController.dispose();
    super.dispose();
  }

  void _handleMotionSetting() {
    _syncAmbientMotion();
    if (mounted) {
      setState(() {});
    }
  }

  void _syncAmbientMotion() {
    if (_reducedMotion) {
      _ambientController.stop();
      _ambientController.value = 0;
      _impactController.stop();
      _impactController.value = 0;
      return;
    }
    if (!_ambientController.isAnimating) {
      _ambientController.repeat();
    }
  }

  void _handleFeedback() {
    final feedback = widget.game.feedbackMessage.value.trim();
    if (feedback.isEmpty || feedback == _lastFeedback) {
      return;
    }
    _lastFeedback = feedback;
    final tone = _toneFor(feedback);
    if (tone == _FeedbackTone.neutral || _reducedMotion) {
      if (mounted) {
        setState(() => _impactTone = tone);
      }
      return;
    }
    setState(() => _impactTone = tone);
    _impactController.forward(from: 0);
  }

  _FeedbackTone _toneFor(String message) {
    final value = message.toLowerCase();
    if (value.contains('failed') ||
        value.contains('blocked') ||
        value.contains('unsafe') ||
        value.contains('chaos') ||
        value.contains('rollback') ||
        value.contains('warning') ||
        value.contains('health reached zero')) {
      return _FeedbackTone.danger;
    }
    if (value.contains('passed') ||
        value.contains('green') ||
        value.contains('stable') ||
        value.contains('complete') ||
        value.contains('deployed') ||
        value.contains('healthy') ||
        value.contains('contained')) {
      return _FeedbackTone.success;
    }
    return _FeedbackTone.neutral;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _ambientController,
        _impactController,
        widget.game.remainingSeconds,
      ]),
      builder: (context, _) {
        final impact = Curves.easeOut.transform(_impactController.value);
        final inverseImpact = 1 - impact;
        final shake = _reducedMotion || _impactTone != _FeedbackTone.danger
            ? 0.0
            : math.sin(impact * math.pi * 7) * inverseImpact * 7;
        final seconds = widget.game.remainingSeconds.value;
        final urgency = seconds <= 15;
        final accent = urgency
            ? const Color(0xFFFF6077)
            : _impactTone == _FeedbackTone.success
                ? const Color(0xFF58F0C2)
                : const Color(0xFF70D6FF);
        final ambientPulse = _reducedMotion
            ? 0.45
            : 0.34 +
                ((math.sin(_ambientController.value * math.pi * 2) + 1) / 2) *
                    0.22;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: accent.withValues(
                      alpha: 0.40 + inverseImpact * 0.34,
                    ),
                    width: urgency ? 1.8 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(
                        alpha: 0.10 + ambientPulse * 0.18,
                      ),
                      blurRadius: 30 + ambientPulse * 18,
                      spreadRadius: inverseImpact * 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: widget.child,
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _GameFeelPainter(
                    accent: accent,
                    phase: _ambientController.value,
                    impact: inverseImpact,
                    reducedMotion: _reducedMotion,
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 12,
                child: _StatusPill(
                  icon: Icons.sensors_rounded,
                  label: 'LIVE // ${seconds}s',
                  accent: accent,
                ),
              ),
              Positioned(
                right: 14,
                top: 12,
                child: _StatusPill(
                  icon: urgency
                      ? Icons.warning_amber_rounded
                      : Icons.bolt_rounded,
                  label: urgency ? 'CRITICAL WINDOW' : 'SYSTEM ACTIVE',
                  accent: accent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _FeedbackTone { neutral, success, danger }

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF050912).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.46)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameFeelPainter extends CustomPainter {
  const _GameFeelPainter({
    required this.accent,
    required this.phase,
    required this.impact,
    required this.reducedMotion,
  });

  final Color accent;
  final double phase;
  final double impact;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final cornerPaint = Paint()
      ..color = accent.withValues(alpha: 0.68 + impact * 0.20)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const inset = 10.0;
    const arm = 22.0;

    void corner(double x, double y, double sx, double sy) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x + arm * sx, y),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + arm * sy),
        cornerPaint,
      );
    }

    corner(inset, inset, 1, 1);
    corner(size.width - inset, inset, -1, 1);
    corner(inset, size.height - inset, 1, -1);
    corner(size.width - inset, size.height - inset, -1, -1);

    if (!reducedMotion) {
      final scanY = 52 + (size.height - 104) * phase;
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            Colors.transparent,
            accent.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, scanY - 14, size.width, 28));
      canvas.drawRect(Rect.fromLTWH(0, scanY - 14, size.width, 28), scanPaint);
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 0.95,
        colors: <Color>[
          Colors.transparent,
          Colors.black.withValues(alpha: 0.02),
          Colors.black.withValues(alpha: 0.34),
        ],
        stops: const <double>[0.50, 0.80, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _GameFeelPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.phase != phase ||
        oldDelegate.impact != impact ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}
