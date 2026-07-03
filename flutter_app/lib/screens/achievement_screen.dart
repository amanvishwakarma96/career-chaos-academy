import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../services/gamification_service.dart';
import '../services/progress_service.dart';
import '../widgets/badge_tile.dart';
import '../widgets/rank_progress_card.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final badges = GamificationService.instance.allBadges;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: SafeArea(
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: ProgressService.instance.badges,
          builder: (context, unlockedBadgeIds, _) {
            final unlockedCount = unlockedBadgeIds.length;
            final progress = badges.isEmpty ? 0.0 : unlockedCount / badges.length;

            return ResponsiveContent(
              child: ListView(
                padding: ResponsiveLayout.pagePadding(context),
                children: [
                  const RankProgressCard(),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Badge Collection',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text('$unlockedCount of ${badges.length} badges unlocked'),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: progress),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...badges.map(
                    (badge) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BadgeTile(
                        badge: badge,
                        isUnlocked: unlockedBadgeIds.contains(badge.id),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
