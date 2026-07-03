import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/responsive_layout.dart';
import '../models/choice_model.dart';
import '../models/mentor/mentor_model.dart';
import '../models/progress_update_result_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../widgets/dialogue_panel.dart';
import '../widgets/info_panel.dart';
import '../widgets/rank_progress_card.dart';
import '../widgets/score_card.dart';
import '../widgets/unlocked_badge_banner.dart';
import '../widgets/motion_feedback_animation.dart';
import '../services/animation_service.dart';
import '../services/professional_simulation_service.dart';
import '../services/mentor_service.dart';
import '../services/career_coach_service.dart';
import '../services/progress_service.dart';
import 'achievement_screen.dart';
import 'role_dashboard_screen.dart';

class ResultScreen extends StatelessWidget {
  final ScenarioModel scenario;
  final ChoiceModel choice;
  final bool isLastChapter;
  final ProgressUpdateResultModel progressUpdate;
  final RoleScenarioModel? roleScenario;

  const ResultScreen({
    super.key,
    required this.scenario,
    required this.choice,
    required this.isLastChapter,
    required this.progressUpdate,
    this.roleScenario,
  });

  void _returnToChapters(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == AppRoutes.chapterList || route.isFirst,
    );
  }

  void _openAchievements(BuildContext context) {
    Navigator.of(context).push(
      AnimationService.instance.motionRoute<void>(
        settings: const RouteSettings(name: AppRoutes.achievement),
        builder: (_) => const AchievementScreen(),
      ),
    );
  }

  void _openDashboard(BuildContext context) {
    final currentRoleScenario = roleScenario;
    if (currentRoleScenario == null) {
      return;
    }
    Navigator.of(context).push(
      AnimationService.instance.motionRoute<void>(
        settings: const RouteSettings(name: AppRoutes.roleDashboard),
        builder: (_) => RoleDashboardScreen(roleScenario: currentRoleScenario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outcome = choice.outcome;
    final consequenceSummary = outcome.consequenceSummary.isNotEmpty
        ? outcome.consequenceSummary
        : outcome.description;
    final mentorFeedback = ProfessionalSimulationService.instance
        .mentorFeedbackForChoice(
      scenario: scenario,
      outcomeFeedback: outcome.mentorFeedback,
    );
    final safeExplanation = outcome.safeExplanation.isNotEmpty
        ? outcome.safeExplanation
        : ProfessionalSimulationService.instance.safeExplanationForScenario(scenario);
    final practicalTakeaway = outcome.practicalTakeaway.isNotEmpty
        ? outcome.practicalTakeaway
        : scenario.practicalTakeaway;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outcome'),
        actions: [
          if (roleScenario != null)
            IconButton(
              tooltip: 'Role Dashboard',
              onPressed: () => _openDashboard(context),
              icon: const Icon(Icons.dashboard_customize),
            ),
          IconButton(
            tooltip: 'Achievements',
            onPressed: () => _openAchievements(context),
            icon: const Icon(Icons.emoji_events),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(
            padding: ResponsiveLayout.pagePadding(context),
            children: [
              UnlockedBadgeBanner(progressUpdate: progressUpdate),
              const SizedBox(height: 12),
              Center(
                child: MotionFeedbackAnimation(
                  type: choice.scoreImpact.chaos > 0
                      ? MotionFeedbackType.failure
                      : MotionFeedbackType.success,
                  size: 96,
                ),
              ),
              const SizedBox(height: 12),
              DialoguePanel(
                speaker: 'Outcome unlocked',
                body: outcome.title,
                icon: Icons.theater_comedy,
              ),
              const SizedBox(height: 12),
              InfoPanel(
                title: 'Consequence',
                body: consequenceSummary,
              ),
              if (progressUpdate.hasConsequences) ...[
                const SizedBox(height: 12),
                _ConsequenceBreakdown(progressUpdate: progressUpdate),
              ],
              const SizedBox(height: 12),
              InfoPanel(
                title: 'Moral Lesson',
                body: outcome.moralLesson,
              ),
              if (scenario.learningObjective.isNotEmpty) ...[
                const SizedBox(height: 12),
                InfoPanel(
                  title: 'Learning Objective',
                  body: scenario.learningObjective,
                ),
              ],
              const SizedBox(height: 12),
              InfoPanel(
                title: 'Professional Mentor Feedback',
                body: mentorFeedback,
              ),
              const SizedBox(height: 12),
              FutureBuilder<MentorFeedbackModel>(
                future: roleScenario == null
                    ? null
                    : MentorService.instance.feedbackAfterChapter(
                        roleScenario: roleScenario!,
                        scenario: scenario,
                        choice: choice,
                        progressUpdate: progressUpdate,
                      ),
                builder: (context, snapshot) {
                  final feedback = snapshot.data;
                  if (feedback == null) {
                    return const InfoPanel(
                      title: 'AI Mentor',
                      body: 'Mentor feedback is preparing. You can continue without waiting.',
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InfoPanel(
                        title: feedback.headline,
                        body: [
                          feedback.feedback,
                          if (feedback.weakAreas.isNotEmpty)
                            'Weak areas: ${feedback.weakAreas.join(', ')}',
                          if (feedback.nextActivitySuggestion.isNotEmpty)
                            'Next activity: ${feedback.nextActivitySuggestion}',
                          if (feedback.safetyNote.isNotEmpty)
                            feedback.safetyNote,
                        ].join('\n\n'),
                      ),
                      if (feedback.hasRoast) ...[
                        const SizedBox(height: 12),
                        InfoPanel(
                          title: 'Roast Mode',
                          body: feedback.roastLine!,
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),
              FutureBuilder<String>(
                future: roleScenario == null
                    ? null
                    : CareerCoachService.instance.generateCoachAdvice(
                        snapshot: ProgressService.instance.currentSnapshot(),
                        roles: roleScenario == null ? const <RoleScenarioModel>[] : <RoleScenarioModel>[roleScenario!],
                      ),
                builder: (context, snapshot) {
                  return InfoPanel(
                    title: 'AI Career Coach',
                    body: snapshot.data ?? 'Career coach is preparing a non-blocking improvement plan.',
                  );
                },
              ),
              const SizedBox(height: 12),
              InfoPanel(
                title: 'Safe Explanation',
                body: safeExplanation,
              ),
              if (practicalTakeaway.isNotEmpty) ...[
                const SizedBox(height: 12),
                InfoPanel(
                  title: 'Practical Takeaway',
                  body: practicalTakeaway,
                ),
              ],
              if (scenario.realWorldConstraints.isNotEmpty || scenario.skillTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                InfoPanel(
                  title: 'Professional Simulation Context',
                  body: [
                    if (scenario.skillLevel.isNotEmpty) 'Skill level: ${scenario.skillLevel}',
                    if (scenario.workflowId.isNotEmpty) 'Workflow: ${scenario.workflowId}',
                    if (scenario.skillTags.isNotEmpty) 'Skills: ${scenario.skillTags.join(', ')}',
                    if (scenario.realWorldConstraints.isNotEmpty) 'Constraints: ${scenario.realWorldConstraints.join(', ')}',
                  ].join('\n'),
                ),
              ],
              if (outcome.debrief.hasContent) ...[
                const SizedBox(height: 12),
                InfoPanel(
                  title: 'Post-Chapter Debrief',
                  body: [
                    if (outcome.debrief.whatWentWell.isNotEmpty)
                      'What went well: ${outcome.debrief.whatWentWell}',
                    if (outcome.debrief.whatWasMissed.isNotEmpty)
                      'What you missed: ${outcome.debrief.whatWasMissed}',
                    if (outcome.debrief.realWorldPrinciple.isNotEmpty)
                      'Real-world principle: ${outcome.debrief.realWorldPrinciple}',
                  ].join('\n\n'),
                ),
              ],
              const SizedBox(height: 12),
              InfoPanel(
                title: scenario.isFinale
                    ? 'Role Ending'
                    : isLastChapter
                        ? 'Role Status'
                        : 'Next Action',
                body: scenario.isFinale
                    ? 'Your current ending: ${progressUpdate.roleEnding ?? 'Pending'}'
                    : isLastChapter
                        ? 'You completed the final available chapter for ${scenario.role.name}. Check the dashboard for strengths and risks.'
                        : 'Return to the chapter list. Cleanup missions or the next chapter may now be available.',
              ),
              const SizedBox(height: 20),
              const RankProgressCard(),
              const SizedBox(height: 12),
              const ScoreCard(),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _returnToChapters(context),
                icon: const Icon(Icons.menu_book),
                label: Text(isLastChapter ? 'View Role Progress' : 'Continue'),
              ),
              const SizedBox(height: 8),
              if (roleScenario != null)
                OutlinedButton.icon(
                  onPressed: () => _openDashboard(context),
                  icon: const Icon(Icons.dashboard_customize),
                  label: const Text('View Role Dashboard'),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openAchievements(context),
                icon: const Icon(Icons.emoji_events),
                label: const Text('View Achievements'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Choose Another Role'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsequenceBreakdown extends StatelessWidget {
  final ProgressUpdateResultModel progressUpdate;

  const _ConsequenceBreakdown({required this.progressUpdate});

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    if (progressUpdate.flagsSet.isNotEmpty) {
      lines.add('Flags set: ${progressUpdate.flagsSet.join(', ')}');
    }
    if (progressUpdate.flagsCleared.isNotEmpty) {
      lines.add('Flags cleared: ${progressUpdate.flagsCleared.join(', ')}');
    }
    if (progressUpdate.unlockedCleanupMissionIds.isNotEmpty) {
      lines.add(
        'Cleanup unlocked: ${progressUpdate.unlockedCleanupMissionIds.join(', ')}',
      );
    }
    if (progressUpdate.storyFlagsSet.isNotEmpty) {
      lines.add('Story flags set: ${progressUpdate.storyFlagsSet.join(', ')}');
    }
    if (progressUpdate.storyFlagsCleared.isNotEmpty) {
      lines.add(
        'Story flags cleared: ${progressUpdate.storyFlagsCleared.join(', ')}',
      );
    }
    final impact = progressUpdate.reputationImpact;
    if (impact.total != 0) {
      lines.add(
        'Reputation impact: Trust ${_signed(impact.trust)}, Safety ${_signed(impact.safety)}, Professionalism ${_signed(impact.professionalism)}, Reliability ${_signed(impact.reliability)}, Stakeholder Confidence ${_signed(impact.stakeholderConfidence)}',
      );
    }
    final relationship = progressUpdate.relationshipImpact;
    if (relationship.total != 0) {
      lines.add(
        'Relationship impact: Mentor ${_signed(relationship.mentorTrust)}, Client ${_signed(relationship.clientTrust)}, Team ${_signed(relationship.teamTrust)}, Public ${_signed(relationship.publicReputation)}',
      );
    }
    if (progressUpdate.delayedConsequenceMessages.isNotEmpty) {
      lines.add(
        'Delayed consequences queued: ${progressUpdate.delayedConsequenceMessages.join(' | ')}',
      );
    }
    return InfoPanel(
      title: 'What Changed',
      body: lines.isEmpty ? 'No persistent consequence changes.' : lines.join('\n'),
    );
  }

  String _signed(int value) => value > 0 ? '+$value' : '$value';
}
