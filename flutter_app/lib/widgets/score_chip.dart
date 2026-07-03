import 'package:flutter/material.dart';

class ScoreChip extends StatefulWidget {
  final String label;
  final int value;

  const ScoreChip({super.key, required this.label, required this.value});

  @override
  State<ScoreChip> createState() => _ScoreChipState();
}

class _ScoreChipState extends State<ScoreChip> {
  late int _oldValue;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant ScoreChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = widget.value >= 0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: _oldValue.toDouble(),
        end: widget.value.toDouble(),
      ),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final valueLabel = animatedValue.round();
        return Chip(
          avatar: Icon(
            isPositive ? Icons.trending_up : Icons.warning_amber,
            size: 16,
          ),
          backgroundColor: isPositive
              ? colorScheme.primaryContainer.withOpacity(0.65)
              : colorScheme.errorContainer,
          label: Text('${widget.label}: $valueLabel'),
        );
      },
    );
  }
}
