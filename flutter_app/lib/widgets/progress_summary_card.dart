import 'package:flutter/material.dart';

class ProgressSummaryCard extends StatelessWidget {
  final String title;
  final int completedChapters;
  final int totalChapters;
  final double progressPercent;

  const ProgressSummaryCard({
    super.key,
    required this.title,
    required this.completedChapters,
    required this.totalChapters,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final percentLabel = (progressPercent * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.auto_stories)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text('$completedChapters of $totalChapters chapters completed'),
                    ],
                  ),
                ),
                Chip(label: Text('$percentLabel%')),
              ],
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progressPercent),
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
  }
}
