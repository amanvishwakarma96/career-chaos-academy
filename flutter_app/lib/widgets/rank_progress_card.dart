import 'package:flutter/material.dart';

import '../models/rank_model.dart';
import '../services/progress_service.dart';

class RankProgressCard extends StatelessWidget {
  const RankProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ProgressService.instance.totalXp,
      builder: (context, xp, _) {
        return ValueListenableBuilder<RankModel>(
          valueListenable: ProgressService.instance.careerRank,
          builder: (context, rank, __) {
            final progress = rank.progressWithinRank(xp);
            final xpToNext = rank.xpToNextRank(xp);
            final subtitle = rank.nextRankXp == null
                ? 'Maximum rank reached'
                : '$xpToNext XP to next rank';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.workspace_premium)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rank.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: xp.toDouble(),
                                  end: xp.toDouble(),
                                ),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, value, _) {
                                  return Text('${value.round()} XP • $subtitle');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(value: value);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
