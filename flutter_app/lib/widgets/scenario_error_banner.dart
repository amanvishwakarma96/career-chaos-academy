import 'package:flutter/material.dart';

import '../services/scenario_service.dart';

class ScenarioErrorBanner extends StatelessWidget {
  final List<ScenarioLoadError> errors;

  const ScenarioErrorBanner({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final visibleErrors = errors.take(2).toList(growable: false);
    final remainingCount = errors.length - visibleErrors.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.error.withOpacity(0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.report_problem, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Some scenarios could not be loaded',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ...visibleErrors.map(
                  (error) => Text(
                    '• ${error.assetPath}: ${error.message}',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
                if (remainingCount > 0)
                  Text(
                    '+ $remainingCount more file issue(s)',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
