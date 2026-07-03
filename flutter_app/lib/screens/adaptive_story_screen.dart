import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/adaptive/adaptive_story_model.dart';
import '../models/adaptive/user_behavior_summary_model.dart';
import '../services/adaptive_story_service.dart';
import '../services/scenario_service.dart';
import '../widgets/info_panel.dart';

class AdaptiveStoryScreen extends StatelessWidget {
  const AdaptiveStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Story Engine')),
      body: SafeArea(
        child: FutureBuilder<ScenarioLoadResult>(
          future: ScenarioService.instance.loadScenarios(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final roles = snapshot.data?.roles ?? const [];
            final summary = AdaptiveStoryService.instance.buildBehaviorSummary(
              roleScenarios: roles,
            );
            final recommendation = AdaptiveStoryService.instance.recommendNextStory(
              roleScenarios: roles,
              summary: summary,
            );
            final draft = recommendation.shouldGenerateSideMission
                ? AdaptiveStoryService.instance.createSafeSideMissionDraft(
                    roleId: recommendation.roleId,
                    summary: summary,
                    recommendation: recommendation,
                  )
                : null;
            return ResponsiveContent(
              child: ListView(
                padding: ResponsiveLayout.pagePadding(context),
                children: [
                  InfoPanel(
                    title: 'Behavior Summary',
                    body: _summaryText(summary),
                  ),
                  const SizedBox(height: 12),
                  InfoPanel(
                    title: 'Recommended Next Story',
                    body: _recommendationText(recommendation),
                  ),
                  if (draft != null) ...[
                    const SizedBox(height: 12),
                    InfoPanel(
                      title: 'Draft Side Mission Preview',
                      body: [
                        'Draft: ${draft.title}',
                        'Status: ${draft.status}',
                        'Safety: ${draft.safetyStatus}',
                        'This draft is intentionally not published. Admin review is required.',
                      ].join('\n'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const InfoPanel(
                    title: 'Safety Rule',
                    body: 'Adaptive stories can recommend drafts, but they never auto-publish. Medical, legal, financial, HR, and safety-sensitive content must pass admin review.',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _summaryText(UserBehaviorSummaryModel summary) {
    return [
      'Patterns: ${summary.behaviorPatterns.isEmpty ? 'None yet' : summary.behaviorPatterns.join(', ')}',
      'Strong skills: ${summary.strongSkills.isEmpty ? 'Still learning' : summary.strongSkills.join(', ')}',
      'Weak skills: ${summary.weakSkills.isEmpty ? 'No major weak area detected' : summary.weakSkills.join(', ')}',
      'Preferred roles: ${summary.preferredRoles.isEmpty ? 'Not enough data' : summary.preferredRoles.join(', ')}',
      'Shortcut choices: ${summary.shortcutChoiceCount}',
      'Repeated failures: ${summary.repeatedFailureCount}',
    ].join('\n');
  }

  String _recommendationText(AdaptiveStoryRecommendationModel recommendation) {
    return [
      'Role: ${recommendation.roleId}',
      if (recommendation.chapterId != null) 'Chapter: ${recommendation.chapterId}',
      'Difficulty: ${recommendation.difficulty}',
      'Activity: ${recommendation.suggestedActivityType}',
      'Why: ${recommendation.reason}',
      'Generate side mission draft: ${recommendation.shouldGenerateSideMission ? 'Yes, admin review required' : 'Not needed now'}',
    ].join('\n');
  }
}
