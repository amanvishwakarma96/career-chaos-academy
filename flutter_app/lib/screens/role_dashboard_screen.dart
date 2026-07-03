import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/role_scenario_model.dart';
import '../models/professional/role_skill_map_model.dart';
import '../services/progress_service.dart';
import '../services/professional_simulation_service.dart';
import '../services/relationship_service.dart';
import '../services/reputation_service.dart';
import '../widgets/info_panel.dart';
import '../widgets/progress_summary_card.dart';

class RoleDashboardScreen extends StatelessWidget {
  final RoleScenarioModel roleScenario;

  const RoleDashboardScreen({super.key, required this.roleScenario});

  @override
  Widget build(BuildContext context) {
    final roleId = roleScenario.role.id;

    return Scaffold(
      appBar: AppBar(title: Text('${roleScenario.role.name} Dashboard')),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: ProgressService.instance.progressByRole,
          builder: (context, _, __) {
            final progress = ProgressService.instance.progressFor(roleId);
            final reputation = ProgressService.instance.reputationFor(roleId);
            final strengths = ReputationService.instance.strengths(reputation);
            final weaknesses = ReputationService.instance.weaknesses(reputation);
            final flags = ProgressService.instance.activeFlagsFor(roleId).toList()
              ..sort();
            final cleanup = ProgressService.instance
                .completedCleanupMissionsFor(roleId)
                .toList()
              ..sort();
            final ending = ProgressService.instance.endingFor(roleId);
            final storyFlags = ProgressService.instance.storyFlagsFor(roleId).toList()..sort();
            final relationship = ProgressService.instance.relationshipFor(roleId);
            final relationshipStrengths = RelationshipService.instance.strengths(relationship);
            final relationshipRisks = RelationshipService.instance.risks(relationship);
            final delayed = ProgressService.instance.delayedConsequencesFor(roleId);

            return ResponsiveContent(
              child: ListView(
                padding: ResponsiveLayout.pagePadding(context),
                children: [
                  ProgressSummaryCard(
                    title: '${roleScenario.role.name} Mastery Progress',
                    completedChapters: progress.completedChapterIds.length,
                    totalChapters: roleScenario.playableChapterCount,
                    progressPercent: progress.progressPercent(
                      roleScenario.playableChapterCount,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<RoleSkillMapModel?>(
                    future: ProfessionalSimulationService.instance
                        .skillMapForRole(roleId),
                    builder: (context, snapshot) {
                      final skillMap = snapshot.data;
                      if (skillMap == null) {
                        return const InfoPanel(
                          title: 'Professional Skill Map',
                          body: 'Skill map is preparing. Gameplay can continue.',
                        );
                      }
                      return _ProfessionalSkillMapCard(skillMap: skillMap);
                    },
                  ),
                  const SizedBox(height: 12),
                  _reputationCard(context, reputation),
                  const SizedBox(height: 12),
                  _relationshipCard(context, relationship),
                  const SizedBox(height: 12),
                  InfoPanel(
                    title: 'Strengths',
                    body: strengths.join('\n'),
                  ),
                  const SizedBox(height: 12),
                  InfoPanel(
                    title: 'Weaknesses / Watch-outs',
                    body: weaknesses.join('\n'),
                  ),
                  const SizedBox(height: 12),
                  InfoPanel(
                    title: 'Relationship Story Signals',
                    body: [
                      if (relationshipStrengths.isNotEmpty)
                        'Strengths: ${relationshipStrengths.join(', ')}',
                      if (relationshipRisks.isNotEmpty)
                        'Risks: ${relationshipRisks.join(', ')}',
                      if (relationshipStrengths.isEmpty && relationshipRisks.isEmpty)
                        'Relationships are currently neutral.',
                    ].join('\n'),
                  ),
                  const SizedBox(height: 12),
                  InfoPanel(
                    title: 'Story Flags',
                    body: storyFlags.isEmpty
                        ? 'No story flags yet. Future dialogue is still neutral.'
                        : storyFlags.join('\n'),
                  ),
                  const SizedBox(height: 12),
                  InfoPanel(
                    title: 'Delayed Consequences',
                    body: delayed.isEmpty
                        ? 'No delayed consequence messages are queued.'
                        : delayed.join('\n'),
                  ),
                  const SizedBox(height: 12),
                  InfoPanel(
                    title: 'Active Consequence Flags',
                    body: flags.isEmpty
                        ? 'No unresolved consequence flags. Keep it professional.'
                        : flags.join('\n'),
                  ),
                  const SizedBox(height: 12),
                  InfoPanel(
                    title: 'Completed Cleanup Missions',
                    body: cleanup.isEmpty
                        ? 'No cleanup missions completed yet.'
                        : cleanup.join('\n'),
                  ),
                  const SizedBox(height: 12),
                  InfoPanel(
                    title: 'Current Role Ending',
                    body: ending ??
                        'No ending calculated yet. Complete the finale to lock your role outcome.',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _reputationCard(BuildContext context, dynamic reputation) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role Reputation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Trust', reputation.trust),
                _chip('Safety', reputation.safety),
                _chip('Professionalism', reputation.professionalism),
                _chip('Reliability', reputation.reliability),
                _chip('Stakeholder Confidence', reputation.stakeholderConfidence),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _relationshipCard(BuildContext context, dynamic relationship) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relationship Scores',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Mentor', relationship.mentorTrust),
                _chip('Client', relationship.clientTrust),
                _chip('Team', relationship.teamTrust),
                _chip('Public', relationship.publicReputation),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int value) {
    final prefix = value > 0 ? '+' : '';
    return Chip(label: Text('$label $prefix$value'));
  }
}

class _ProfessionalSkillMapCard extends StatelessWidget {
  final RoleSkillMapModel skillMap;

  const _ProfessionalSkillMapCard({required this.skillMap});

  @override
  Widget build(BuildContext context) {
    final skills = skillMap.skills
        .map((skill) => '${skill.name} (${skill.level})')
        .join('\n');
    final workflows = skillMap.workflows
        .map((workflow) => '• ${workflow.title}: ${workflow.steps.join(' → ')}')
        .join('\n');
    final glossary = skillMap.glossary
        .take(4)
        .map((term) => '${term.term}: ${term.definition}')
        .join('\n');
    return InfoPanel(
      title: 'Professional Skill Map',
      body: [
        'Mentor: ${skillMap.mentorName}',
        if (skills.isNotEmpty) '\nSkills:\n$skills',
        if (workflows.isNotEmpty) '\nRealistic Workflows:\n$workflows',
        if (skillMap.safetyGuardrails.isNotEmpty)
          '\nSafety Guardrails:\n${skillMap.safetyGuardrails.join('\n')}',
        if (glossary.isNotEmpty) '\nGlossary:\n$glossary',
      ].join('\n'),
    );
  }
}
