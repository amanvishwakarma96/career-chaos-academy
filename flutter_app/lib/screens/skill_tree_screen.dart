
import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/role_scenario_model.dart';
import '../models/skill_tree/skill_tree_model.dart';
import '../services/progress_service.dart';
import '../services/skill_tree_service.dart';
import '../widgets/empty_state.dart';

class SkillTreeScreen extends StatelessWidget {
  final RoleScenarioModel roleScenario;

  const SkillTreeScreen({super.key, required this.roleScenario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${roleScenario.role.name} Skill Tree'),
      ),
      body: SafeArea(
        child: FutureBuilder<SkillTreeModel?>(
          future: SkillTreeService.instance.skillTreeForRole(roleScenario.role.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final tree = snapshot.data;
            if (tree == null || tree.nodes.isEmpty) {
              return const EmptyState(
                icon: Icons.account_tree_outlined,
                title: 'Skill tree unavailable',
                message: 'This role does not have a skill tree yet.',
              );
            }
            return ValueListenableBuilder<Map<String, SkillTreeProgressModel>>(
              valueListenable: ProgressService.instance.skillTreeProgressByRole,
              builder: (context, progressByRole, _) {
                final progress = progressByRole[tree.roleId] ?? SkillTreeProgressModel(roleId: tree.roleId);
                final mastery = progress.masteryPercentForTree(tree);
                return ResponsiveContent(
                  child: ListView(
                    padding: ResponsiveLayout.pagePadding(context),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tree.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 8),
                              Text(tree.description),
                              const SizedBox(height: 14),
                              LinearProgressIndicator(value: mastery / 100),
                              const SizedBox(height: 8),
                              Text('${mastery.toStringAsFixed(0)}% role skill mastery'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...tree.nodes.map((node) => _SkillNodeCard(node: node, progress: progress)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SkillNodeCard extends StatelessWidget {
  final SkillNodeModel node;
  final SkillTreeProgressModel progress;

  const _SkillNodeCard({required this.node, required this.progress});

  @override
  Widget build(BuildContext context) {
    final nodeProgress = progress.progressFor(node.id);
    final percent = nodeProgress.masteryPercent(masteryTarget: node.masteryTarget);
    final unlocked = progress.isNodeUnlocked(node);
    final mastered = nodeProgress.isMastered(masteryTarget: node.masteryTarget);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  mastered ? Icons.workspace_premium : unlocked ? Icons.lock_open : Icons.lock,
                  color: mastered ? colorScheme.primary : unlocked ? colorScheme.secondary : colorScheme.outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(node.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                Chip(label: Text(node.level)),
              ],
            ),
            const SizedBox(height: 8),
            Text(node.description),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: unlocked ? percent / 100 : 0),
            const SizedBox(height: 8),
            Text(unlocked ? '$percent% mastery • ${node.category}' : 'Locked until prerequisites are mastered.'),
            if (node.prerequisiteNodeIds.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Prerequisites: ${node.prerequisiteNodeIds.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (node.linkedChapterIds.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Linked chapters: ${node.linkedChapterIds.length}', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (node.linkedMiniGameIds.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Linked mini-games: ${node.linkedMiniGameIds.length}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
