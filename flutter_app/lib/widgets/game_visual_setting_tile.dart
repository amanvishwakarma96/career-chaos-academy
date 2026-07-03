import 'package:flutter/material.dart';

import '../models/game_visual_settings_model.dart';
import '../services/game_visual_settings_service.dart';

class GameVisualSettingTile extends StatelessWidget {
  const GameVisualSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GameVisualSettingsService.instance;

    return ValueListenableBuilder<GameVisualQuality>(
      valueListenable: service.quality,
      builder: (context, quality, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game Visual Quality',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose the visual-effects budget. This does not change scores or progression.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GameVisualQuality.values
                    .map(
                      (item) => ChoiceChip(
                        selected: item == quality,
                        avatar: Icon(_iconFor(item), size: 18),
                        label: Text(item.label),
                        onSelected: (_) => service.setQuality(item),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Container(
                  key: ValueKey<GameVisualQuality>(quality),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.55),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        quality.usesHeavyEffects
                            ? Icons.auto_awesome
                            : quality.usesAmbientEffects
                                ? Icons.motion_photos_auto
                                : Icons.speed,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(quality.description)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconFor(GameVisualQuality quality) {
    switch (quality) {
      case GameVisualQuality.performance:
        return Icons.speed;
      case GameVisualQuality.balanced:
        return Icons.balance;
      case GameVisualQuality.cinematic:
        return Icons.auto_awesome;
    }
  }
}
