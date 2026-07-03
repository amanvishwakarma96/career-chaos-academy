import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/responsive_layout.dart';
import '../models/role_progress_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../services/progress_service.dart';
import '../services/scenario_service.dart';
import '../services/animation_service.dart';
import '../widgets/chapter_card.dart';
import '../widgets/info_panel.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/rank_progress_card.dart';
import '../widgets/score_card.dart';
import 'achievement_screen.dart';
import 'role_dashboard_screen.dart';
import 'scenario_screen.dart';
import 'skill_tree_screen.dart';

class ChapterListScreen extends StatelessWidget {
  final RoleScenarioModel roleScenario;

  const ChapterListScreen({super.key, required this.roleScenario});

  void _openChapter(BuildContext context, ScenarioModel chapter) {
    final roleId = roleScenario.role.id;
    final progress = ProgressService.instance.progressFor(roleId);
    final activeFlags = ProgressService.instance.activeFlagsFor(roleId);
    final cleanupIds = ProgressService.instance.unlockedCleanupMissionIdsFor(
      roleId,
    );
    final storyFlags = ProgressService.instance.storyFlagsFor(roleId);
    final relationship = ProgressService.instance.relationshipFor(roleId);
    final availability = ScenarioService.instance.chapterAvailability(
      chapter: chapter,
      progress: progress,
      activeFlags: activeFlags,
      unlockedCleanupMissionIds: cleanupIds,
      storyFlags: storyFlags,
      relationship: relationship,
    );
    final chapterIndex = roleScenario.chapters.indexWhere(
      (item) => item.id == chapter.id,
    );
    final mainIndex = roleScenario.mainChapters.indexWhere(
      (item) => item.id == chapter.id,
    );

    if (mainIndex >= 0 &&
        !ProgressService.instance.isChapterUnlocked(
          roleId: roleId,
          chapterIndex: mainIndex,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous main chapter first.'),
        ),
      );
      return;
    }

    if (!availability.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            availability.reasons.isEmpty
                ? 'This chapter is blocked right now.'
                : availability.reasons.first,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      AnimationService.instance.motionRoute<void>(
        settings: const RouteSettings(name: AppRoutes.scenario),
        transition: MotionRouteTransition.slideLeft,
        builder: (_) => ScenarioScreen(
          roleScenario: roleScenario,
          scenario: chapter,
          chapterIndex: chapterIndex < 0 ? 0 : chapterIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roleScenario.role.name),
        actions: [
          IconButton(
            tooltip: 'Skill Tree',
            onPressed: () {
              Navigator.of(context).push(
                AnimationService.instance.motionRoute<void>(
                  settings: const RouteSettings(name: AppRoutes.skillTree),
                  builder: (_) => SkillTreeScreen(roleScenario: roleScenario),
                ),
              );
            },
            icon: const Icon(Icons.account_tree),
          ),
          IconButton(
            tooltip: 'Role Dashboard',
            onPressed: () {
              Navigator.of(context).push(
                AnimationService.instance.motionRoute<void>(
                  settings: const RouteSettings(name: AppRoutes.roleDashboard),
                  builder: (_) => RoleDashboardScreen(roleScenario: roleScenario),
                ),
              );
            },
            icon: const Icon(Icons.dashboard_customize),
          ),
          IconButton(
            tooltip: 'Achievements',
            onPressed: () {
              Navigator.of(context).push(
                AnimationService.instance.motionRoute<void>(
                  settings: const RouteSettings(name: AppRoutes.achievement),
                  builder: (_) => const AchievementScreen(),
                ),
              );
            },
            icon: const Icon(Icons.emoji_events),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Map<String, RoleProgressModel>>(
          valueListenable: ProgressService.instance.progressByRole,
          builder: (context, _, __) {
            return ValueListenableBuilder<Map<String, Set<String>>>(
              valueListenable: ProgressService.instance.activeFlagsByRole,
              builder: (context, __, ___) {
                final progress = ProgressService.instance.progressFor(
                  roleScenario.role.id,
                );
                final progressPercent = progress.progressPercent(
                  roleScenario.playableChapterCount,
                );
                final cleanupIds = ProgressService.instance
                    .unlockedCleanupMissionIdsFor(roleScenario.role.id);

                return ResponsiveContent(
                  child: ListView(
                    padding: ResponsiveLayout.pagePadding(context),
                    children: [
                      Text(
                        roleScenario.role.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ProgressSummaryCard(
                        title: '${roleScenario.role.name} Progress',
                        completedChapters: progress.completedChapterIds.length,
                        totalChapters: roleScenario.playableChapterCount,
                        progressPercent: progressPercent,
                      ),
                      const SizedBox(height: 12),
                      const RankProgressCard(),
                      const SizedBox(height: 12),
                      const ScoreCard(),
                      const SizedBox(height: 20),
                      _buildSection(
                        context: context,
                        title: 'Main Chapters',
                        emptyMessage: 'No main chapters found.',
                        chapters: roleScenario.mainChapters,
                        progress: progress,
                        cleanupIds: cleanupIds,
                      ),
                      if (roleScenario.cleanupMissions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          context: context,
                          title: 'Cleanup Missions',
                          emptyMessage:
                              'Cleanup missions unlock when risky choices create problems.',
                          chapters: roleScenario.cleanupMissions,
                          progress: progress,
                          cleanupIds: cleanupIds,
                        ),
                      ],
                      if (roleScenario.finaleChapters.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          context: context,
                          title: 'Finale / Mastery Check',
                          emptyMessage: 'No finale chapter found yet.',
                          chapters: roleScenario.finaleChapters,
                          progress: progress,
                          cleanupIds: cleanupIds,
                        ),
                      ],
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

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String emptyMessage,
    required List<ScenarioModel> chapters,
    required RoleProgressModel progress,
    required Set<String> cleanupIds,
  }) {
    final activeFlags = ProgressService.instance.activeFlagsFor(
      roleScenario.role.id,
    );
    final storyFlags = ProgressService.instance.storyFlagsFor(roleScenario.role.id);
    final relationship = ProgressService.instance.relationshipFor(roleScenario.role.id);
    final visibleChapters = chapters.where((chapter) {
      if (chapter.isCleanupMission) {
        return cleanupIds.contains(chapter.id) ||
            progress.isChapterCompleted(chapter.id);
      }
      return true;
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        if (visibleChapters.isEmpty)
          InfoPanel(title: title, body: emptyMessage)
        else
          ...visibleChapters.asMap().entries.map((entry) {
            final localIndex = entry.key;
            final chapter = entry.value;
            final mainIndex = roleScenario.mainChapters.indexWhere(
              (item) => item.id == chapter.id,
            );
            final availability = ScenarioService.instance.chapterAvailability(
              chapter: chapter,
              progress: progress,
              activeFlags: activeFlags,
              unlockedCleanupMissionIds: cleanupIds,
              storyFlags: storyFlags,
              relationship: relationship,
            );
            ChapterProgressState state;
            if (progress.isChapterCompleted(chapter.id)) {
              state = ChapterProgressState.completed;
            } else if (!availability.isAvailable) {
              state = ChapterProgressState.blocked;
            } else if (mainIndex >= 0 && !progress.isChapterUnlocked(mainIndex)) {
              state = ChapterProgressState.locked;
            } else {
              state = ChapterProgressState.current;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChapterCard(
                chapter: chapter,
                chapterNumber: mainIndex >= 0 ? mainIndex + 1 : localIndex + 1,
                state: state,
                availabilityMessage: availability.reasons.isEmpty
                    ? null
                    : availability.reasons.first,
                onTap: () => _openChapter(context, chapter),
              ),
            );
          }),
      ],
    );
  }
}
