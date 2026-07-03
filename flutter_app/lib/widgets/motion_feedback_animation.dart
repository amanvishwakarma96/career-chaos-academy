import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../services/animation_service.dart';

enum MotionFeedbackType { success, failure, badge }

class MotionFeedbackAnimation extends StatelessWidget {
  final MotionFeedbackType type;
  final double size;
  final bool repeat;

  const MotionFeedbackAnimation({
    super.key,
    required this.type,
    this.size = 96,
    this.repeat = false,
  });

  String get _assetPath {
    switch (type) {
      case MotionFeedbackType.success:
        return 'assets/game/lottie/success.json';
      case MotionFeedbackType.failure:
        return 'assets/game/lottie/failure.json';
      case MotionFeedbackType.badge:
        return 'assets/game/lottie/badge_unlock.json';
    }
  }

  IconData get _fallbackIcon {
    switch (type) {
      case MotionFeedbackType.success:
        return Icons.check_circle;
      case MotionFeedbackType.failure:
        return Icons.warning_amber;
      case MotionFeedbackType.badge:
        return Icons.emoji_events;
    }
  }

  Color _color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case MotionFeedbackType.success:
        return Colors.greenAccent.shade700;
      case MotionFeedbackType.failure:
        return scheme.error;
      case MotionFeedbackType.badge:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AnimationService.instance.reducedMotion,
      builder: (context, reducedMotion, _) {
        if (reducedMotion) {
          return Icon(_fallbackIcon, size: size * 0.62, color: _color(context));
        }

        return SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            _assetPath,
            repeat: repeat,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(_fallbackIcon, size: size * 0.62, color: _color(context));
            },
          ),
        );
      },
    );
  }
}
