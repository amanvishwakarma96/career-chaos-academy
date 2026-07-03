import 'package:flutter/material.dart';

import '../models/mini_game_progress_model.dart';
import '../models/mini_game_result_model.dart';

class MiniGameStatusCard extends StatelessWidget {
  final MiniGameProgressModel? savedProgress;
  final MiniGameResultModel? currentResult;
  final VoidCallback onStartPressed;
  final String? titleOverride;
  final String? descriptionOverride;
  final String buttonLabel;

  const MiniGameStatusCard({
    super.key,
    required this.savedProgress,
    required this.currentResult,
    required this.onStartPressed,
    this.titleOverride,
    this.descriptionOverride,
    this.buttonLabel = 'Start Mini-game',
  });

  bool get _isCompleted => savedProgress != null || currentResult != null;
  bool get _isSuccess => currentResult?.isSuccess ?? savedProgress?.isSuccess ?? false;

  @override
  Widget build(BuildContext context) {
    final title = titleOverride ??
        (_isCompleted ? 'Mini-game completed' : 'Mini-game available');
    final subtitle = descriptionOverride ??
        (_isCompleted
        ? _isSuccess
            ? 'Great work. Your performance score has been saved.'
            : 'You survived the mini-game chaos. The funny consequence has been saved.'
        : 'Complete this role-specific challenge before choosing the story outcome.');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isCompleted
                      ? _isSuccess
                          ? Icons.check_circle
                          : Icons.warning_amber
                      : Icons.sports_esports,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            if (!_isCompleted) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onStartPressed,
                icon: const Icon(Icons.play_arrow),
                label: Text(buttonLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
