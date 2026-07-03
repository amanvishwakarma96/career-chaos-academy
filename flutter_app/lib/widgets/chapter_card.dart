import 'package:flutter/material.dart';

import '../models/role_progress_model.dart';
import '../models/scenario_model.dart';

class ChapterCard extends StatelessWidget {
  final ScenarioModel chapter;
  final int chapterNumber;
  final ChapterProgressState state;
  final VoidCallback onTap;
  final String? availabilityMessage;

  const ChapterCard({
    super.key,
    required this.chapter,
    required this.chapterNumber,
    required this.state,
    required this.onTap,
    this.availabilityMessage,
  });

  bool get _isLocked => state == ChapterProgressState.locked || state == ChapterProgressState.blocked;

  IconData get _stateIcon {
    switch (state) {
      case ChapterProgressState.completed:
        return Icons.check_circle;
      case ChapterProgressState.current:
        return Icons.play_circle_fill;
      case ChapterProgressState.locked:
        return Icons.lock;
      case ChapterProgressState.blocked:
        return Icons.block;
    }
  }

  String get _stateLabel {
    switch (state) {
      case ChapterProgressState.completed:
        return 'Completed';
      case ChapterProgressState.current:
        return 'Current';
      case ChapterProgressState.locked:
        return 'Locked';
      case ChapterProgressState.blocked:
        return 'Blocked';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: _isLocked ? 0 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _isLocked
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.primaryContainer,
                child: Icon(
                  _stateIcon,
                  color: _isLocked
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapter $chapterNumber',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      chapter.theme,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (availabilityMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        availabilityMessage!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(_stateLabel),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text(chapter.difficulty),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (chapter.isCleanupMission)
                          const Chip(
                            avatar: Icon(Icons.cleaning_services, size: 16),
                            label: Text('Cleanup'),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (chapter.isFinale)
                          const Chip(
                            avatar: Icon(Icons.workspace_premium, size: 16),
                            label: Text('Finale'),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (chapter.miniGame != null)
                          const Chip(
                            avatar: Icon(Icons.sports_esports, size: 16),
                            label: Text('Mini-game'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
