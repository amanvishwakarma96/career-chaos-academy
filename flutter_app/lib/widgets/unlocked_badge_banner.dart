import 'dart:async';

import 'package:flutter/material.dart';

import '../models/progress_update_result_model.dart';
import '../services/animation_service.dart';
import '../services/audio_service.dart';
import 'motion_feedback_animation.dart';

class UnlockedBadgeBanner extends StatefulWidget {
  final ProgressUpdateResultModel progressUpdate;

  const UnlockedBadgeBanner({
    super.key,
    required this.progressUpdate,
  });

  @override
  State<UnlockedBadgeBanner> createState() => _UnlockedBadgeBannerState();
}

class _UnlockedBadgeBannerState extends State<UnlockedBadgeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _turnAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationService.instance.duration(
        const Duration(milliseconds: 620),
      ),
    )..forward();
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _turnAnimation = Tween<double>(begin: -0.04, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    if (widget.progressUpdate.hasNewBadges || widget.progressUpdate.didRankUp) {
      unawaited(AudioService.instance.playBadgeUnlock());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.progressUpdate;
    final messages = <String>[];

    if (update.xpGained > 0) {
      messages.add('+${update.xpGained} XP earned');
    }

    if (update.didRankUp) {
      messages.add('Rank up: ${update.currentRank.title}');
    }

    if (update.hasNewBadges) {
      final badgeNames = update.newlyUnlockedBadges
          .map((badge) => badge.title)
          .join(', ');
      messages.add('Badge unlocked: $badgeNames');
    }

    if (messages.isEmpty) {
      if (update.wasAlreadyCompleted) {
        messages.add('Chapter already completed. Progress was preserved.');
      } else {
        return const SizedBox.shrink();
      }
    }

    if (AnimationService.instance.isReducedMotion) {
      return _BadgeContent(
        messages: messages,
        showAnimation: update.hasNewBadges || update.didRankUp,
      );
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RotationTransition(
          turns: _turnAnimation,
          child: _BadgeContent(
            messages: messages,
            showAnimation: update.hasNewBadges || update.didRankUp,
          ),
        ),
      ),
    );
  }
}


class _BadgeContent extends StatelessWidget {
  final List<String> messages;
  final bool showAnimation;

  const _BadgeContent({
    required this.messages,
    required this.showAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAnimation)
            const MotionFeedbackAnimation(
              type: MotionFeedbackType.badge,
              size: 64,
            )
          else
            CircleAvatar(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.celebration),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievement Update',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                ...messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message,
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
