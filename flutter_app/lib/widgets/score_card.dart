import 'package:flutter/material.dart';

import '../models/score_model.dart';
import '../services/score_service.dart';
import 'score_chip.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScoreModel>(
      valueListenable: ScoreService.instance.score,
      builder: (context, score, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ScoreChip(label: 'Skill', value: score.skill),
                    ScoreChip(label: 'Discipline', value: score.discipline),
                    ScoreChip(label: 'Ethics', value: score.ethics),
                    ScoreChip(
                      label: 'Communication',
                      value: score.communication,
                    ),
                    ScoreChip(label: 'Chaos', value: score.chaos),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
