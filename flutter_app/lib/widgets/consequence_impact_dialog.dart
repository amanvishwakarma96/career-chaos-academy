import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/score_model.dart';
import 'motion_feedback_animation.dart';

class ConsequenceImpactDialog extends StatelessWidget {
  const ConsequenceImpactDialog({
    super.key,
    required this.title,
    required this.summary,
    required this.scoreImpact,
    required this.isPositive,
  });

  final String title;
  final String summary;
  final ScoreModel scoreImpact;
  final bool isPositive;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String summary,
    required ScoreModel scoreImpact,
    required bool isPositive,
  }) async {
    HapticFeedback.mediumImpact();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Consequence result',
      barrierColor: Colors.black.withOpacity(0.82),
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ConsequenceImpactDialog(
          title: title,
          summary: summary,
          scoreImpact: scoreImpact,
          isPositive: isPositive,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = isPositive
        ? const Color(0xFF66E3A4)
        : const Color(0xFFFF6B6B);

    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: accent.withOpacity(0.7), width: 1.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  accent.withOpacity(0.22),
                  const Color(0xFF121426),
                  const Color(0xFF070913),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.30),
                  blurRadius: 44,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MotionFeedbackAnimation(
                  type: isPositive
                      ? MotionFeedbackType.success
                      : MotionFeedbackType.failure,
                  size: 112,
                ),
                const SizedBox(height: 10),
                Text(
                  isPositive ? 'DECISION LOCKED' : 'CHAOS TRIGGERED',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  summary.isEmpty
                      ? 'Your decision changes the direction of this scenario.'
                      : summary,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ImpactChip(label: 'Skill', value: scoreImpact.skill),
                    _ImpactChip(
                      label: 'Discipline',
                      value: scoreImpact.discipline,
                    ),
                    _ImpactChip(label: 'Ethics', value: scoreImpact.ethics),
                    _ImpactChip(
                      label: 'Communication',
                      value: scoreImpact.communication,
                    ),
                    _ImpactChip(
                      label: 'Chaos',
                      value: scoreImpact.chaos,
                      inverse: true,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Continue to Debrief'),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  const _ImpactChip({
    required this.label,
    required this.value,
    this.inverse = false,
  });

  final String label;
  final int value;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final isGood = inverse ? value <= 0 : value >= 0;
    final color = isGood
        ? const Color(0xFF66E3A4)
        : const Color(0xFFFF8A80);
    final prefix = value > 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.38)),
      ),
      child: Text(
        '$label $prefix$value',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}
