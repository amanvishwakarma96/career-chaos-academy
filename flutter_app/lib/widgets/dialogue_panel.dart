import 'package:flutter/material.dart';

import 'typing_text.dart';

class DialoguePanel extends StatelessWidget {
  final String speaker;
  final String body;
  final IconData icon;
  final bool useTypingEffect;

  const DialoguePanel({
    super.key,
    required this.speaker,
    required this.body,
    this.icon = Icons.record_voice_over,
    this.useTypingEffect = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.52),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  speaker,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.78),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: useTypingEffect
                  ? TypingText(
                      text: body,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    )
                  : Text(
                      body,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
