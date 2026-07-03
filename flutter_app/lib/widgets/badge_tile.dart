import 'package:flutter/material.dart';

import '../core/role_icon_mapper.dart';
import '../models/badge_model.dart';

class BadgeTile extends StatelessWidget {
  final BadgeModel badge;
  final bool isUnlocked;

  const BadgeTile({
    super.key,
    required this.badge,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = RoleIconMapper.fromKey(badge.iconKey);

    return AnimatedOpacity(
      opacity: isUnlocked ? 1 : 0.72,
      duration: const Duration(milliseconds: 260),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isUnlocked
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: isUnlocked
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                child: Icon(isUnlocked ? icon : Icons.lock),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            badge.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Chip(
                          avatar: Icon(
                            isUnlocked ? Icons.check_circle : Icons.lock_clock,
                            size: 16,
                          ),
                          label: Text(isUnlocked ? 'Unlocked' : 'Locked'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(isUnlocked ? badge.description : badge.lockedHint),
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
