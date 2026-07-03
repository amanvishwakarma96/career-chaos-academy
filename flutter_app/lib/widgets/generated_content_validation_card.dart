import 'package:flutter/material.dart';

import '../content_generation/generated_content_validation_result.dart';

class GeneratedContentValidationCard extends StatelessWidget {
  final GeneratedContentValidationResult result;

  const GeneratedContentValidationCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusIcon = result.isAppReady
        ? Icons.verified
        : result.hasErrors
            ? Icons.error
            : Icons.info;
    final statusTitle = result.isAppReady
        ? 'Valid and ready for human review'
        : result.hasErrors
            ? 'Fix blocking issues first'
            : 'Waiting for generated JSON';
    final statusColor = result.isAppReady
        ? colorScheme.primary
        : result.hasErrors
            ? colorScheme.error
            : colorScheme.secondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (result.issues.isEmpty)
              const Text('No validation issues found.')
            else
              ...result.issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _IssueRow(issue: issue),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final GeneratedContentValidationIssue issue;

  const _IssueRow({required this.issue});

  @override
  Widget build(BuildContext context) {
    final isError = issue.isError;
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.cancel : Icons.warning_amber, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${issue.label} • ${issue.path}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(issue.message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
