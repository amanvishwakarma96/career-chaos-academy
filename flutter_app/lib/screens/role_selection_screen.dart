import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/responsive_layout.dart';
import '../models/role_progress_model.dart';
import '../services/progress_service.dart';
import '../services/scenario_service.dart';
import '../services/theme_service.dart';
import '../services/animation_service.dart';
import '../services/future_scope/feature_flag_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/rank_progress_card.dart';
import '../widgets/role_card.dart';
import '../widgets/scenario_error_banner.dart';
import '../widgets/score_card.dart';
import '../widgets/motion_setting_tile.dart';
import '../widgets/audio_setting_tile.dart';
import '../widgets/game_visual_setting_tile.dart';
import 'achievement_screen.dart';
import 'adaptive_story_screen.dart';
import 'activity_hub_screen.dart';
import 'content_generator_screen.dart';
import 'flame_game_host_screen.dart';
import 'interview_mode_screen.dart';
import 'learning_analytics_dashboard_screen.dart';
import 'monetization_screen.dart';
import 'production_security_screen.dart';
import 'future_architecture_screen.dart';
import 'mentor_selection_screen.dart';
import 'certification_engine_screen.dart';
import 'corporate_college_edition_screen.dart';
import 'chapter_list_screen.dart';
import 'coach_dashboard_screen.dart';
import 'scenario_pack_marketplace_screen.dart';
import 'team_simulation_screen.dart';
import 'voice_settings_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late Future<ScenarioLoadResult> _scenarioFuture;

  @override
  void initState() {
    super.initState();
    _scenarioFuture = _loadInitialData();
  }

  Future<ScenarioLoadResult> _loadInitialData() async {
    return ScenarioService.instance.loadScenarios();
  }

  void _reloadScenarios() {
    setState(() {
      _scenarioFuture = _loadInitialData();
    });
  }

  Future<void> _confirmResetProgress() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset progress?'),
          content: const Text(
            'This will clear completed chapters, unlocked chapters, scores, XP, ranks, and badges saved on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) {
      return;
    }

    await ProgressService.instance.reset();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress has been reset for testing.')),
    );
  }

  void _toggleTheme() {
    ThemeService.instance.toggleLightDark();
  }

  void _openMotionSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return const SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: MotionSettingTile(),
                ),
                Divider(height: 1),
                GameVisualSettingTile(),
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: AudioSettingTile(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_GameHubAction> _gameHubActions() {
    final flags = FeatureFlagService.instance;
    final actions = <_GameHubAction>[
      _GameHubAction(
        title: 'Achievements',
        subtitle: 'Badges, XP, and career ranks',
        icon: Icons.emoji_events,
        routeName: AppRoutes.achievement,
        builder: (_) => const AchievementScreen(),
      ),
    ];

    void addIf(
      bool condition, {
      required String title,
      required String subtitle,
      required IconData icon,
      required String routeName,
      required WidgetBuilder builder,
    }) {
      if (!condition) {
        return;
      }
      actions.add(
        _GameHubAction(
          title: title,
          subtitle: subtitle,
          icon: icon,
          routeName: routeName,
          builder: builder,
        ),
      );
    }

    addIf(
      flags.isEnabled('activity_hub'),
      title: 'Activity Hub',
      subtitle: 'Daily and weekly challenges',
      icon: Icons.extension,
      routeName: AppRoutes.activityHub,
      builder: (_) => const ActivityHubScreen(),
    );
    addIf(
      flags.isEnabled('flame_minigames'),
      title: 'Game Lab',
      subtitle: 'Flame-powered mini-games',
      icon: Icons.videogame_asset,
      routeName: AppRoutes.flameMiniGameHost,
      builder: (_) => const FlameGameHostScreen(),
    );
    addIf(
      flags.isEnabled('ai_mentor'),
      title: 'AI Mentor',
      subtitle: 'Feedback and weak-area coaching',
      icon: Icons.psychology_alt,
      routeName: AppRoutes.mentorSelection,
      builder: (_) => const MentorSelectionScreen(),
    );
    addIf(
      flags.isEnabled('career_coach'),
      title: 'Career Coach',
      subtitle: 'Personal roadmap and weekly plan',
      icon: Icons.school,
      routeName: AppRoutes.careerCoach,
      builder: (_) => const CoachDashboardScreen(),
    );
    addIf(
      flags.isEnabled('adaptive_story_engine'),
      title: 'Adaptive Story',
      subtitle: 'Behavior-aware story missions',
      icon: Icons.auto_stories,
      routeName: AppRoutes.adaptiveStory,
      builder: (_) => const AdaptiveStoryScreen(),
    );
    addIf(
      flags.isEnabled('team_simulation'),
      title: 'Team Simulation',
      subtitle: 'Multiplayer role rooms',
      icon: Icons.groups_3,
      routeName: AppRoutes.teamSimulation,
      builder: (_) => const TeamSimulationScreen(),
    );
    addIf(
      flags.isEnabled('interview_mode'),
      title: 'Interview Mode',
      subtitle: 'Technical and behavioral rounds',
      icon: Icons.record_voice_over,
      routeName: AppRoutes.interviewMode,
      builder: (_) => const InterviewModeScreen(),
    );
    addIf(
      flags.isEnabled('certification_engine'),
      title: 'Certification',
      subtitle: 'Assessments and certificates',
      icon: Icons.workspace_premium,
      routeName: AppRoutes.certificationEngine,
      builder: (_) => const CertificationEngineScreen(),
    );
    addIf(
      flags.isEnabled('scenario_marketplace'),
      title: 'Scenario Packs',
      subtitle: 'Preview and download new stories',
      icon: Icons.storefront,
      routeName: AppRoutes.scenarioMarketplace,
      builder: (_) => const ScenarioPackMarketplaceScreen(),
    );
    addIf(
      flags.isEnabled('ai_voice_conversation'),
      title: 'Voice & Chat',
      subtitle: 'Character conversation settings',
      icon: Icons.forum,
      routeName: AppRoutes.aiVoiceConversation,
      builder: (_) => const VoiceSettingsScreen(),
    );
    addIf(
      flags.isEnabled('learning_analytics'),
      title: 'Learning Analytics',
      subtitle: 'Personal progress insights',
      icon: Icons.query_stats,
      routeName: AppRoutes.learningAnalytics,
      builder: (_) => const LearningAnalyticsDashboardScreen(),
    );
    addIf(
      flags.isEnabled('corporate_college_edition'),
      title: 'Organization Mode',
      subtitle: 'Batches, assignments, and reports',
      icon: Icons.business_center,
      routeName: AppRoutes.corporateCollegeEdition,
      builder: (_) => const CorporateCollegeEditionScreen(),
    );
    addIf(
      flags.isEnabled('monetization_system'),
      title: 'Premium Content',
      subtitle: 'Products and entitlement preview',
      icon: Icons.payments,
      routeName: AppRoutes.monetizationSystem,
      builder: (_) => const MonetizationScreen(),
    );
    addIf(
      flags.isEnabled('production_security_scale'),
      title: 'Security Center',
      subtitle: 'Production controls and checklist',
      icon: Icons.security,
      routeName: AppRoutes.productionSecurity,
      builder: (_) => const ProductionSecurityScreen(),
    );
    addIf(
      flags.isEnabled('ai_scenario_lab'),
      title: 'AI Scenario Lab',
      subtitle: 'Generate and review scenario drafts',
      icon: Icons.auto_awesome,
      routeName: AppRoutes.contentGenerator,
      builder: (_) => const ContentGeneratorScreen(),
    );
    actions.add(
      _GameHubAction(
        title: 'Future Architecture',
        subtitle: 'Feature flags and platform roadmap',
        icon: Icons.account_tree,
        routeName: AppRoutes.futureArchitecture,
        builder: (_) => const FutureArchitectureScreen(),
      ),
    );
    return actions;
  }

  void _openHubAction(BuildContext sheetContext, _GameHubAction action) {
    Navigator.of(sheetContext).pop();
    Navigator.of(context).push(
      AnimationService.instance.motionRoute<void>(
        settings: RouteSettings(name: action.routeName),
        transition: MotionRouteTransition.slideUp,
        builder: action.builder,
      ),
    );
  }

  void _openGameHub() {
    final actions = _gameHubActions();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF0C0E18),
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.84,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Career Chaos Game Hub',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose a mode without crowding the main game screen.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.18,
                    ),
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return _GameHubActionCard(
                        action: action,
                        onTap: () => _openHubAction(sheetContext, action),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _confirmResetProgress();
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset Test Progress'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.18)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Chaos Academy'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.instance.themeMode,
            builder: (context, themeMode, _) {
              return IconButton(
                tooltip: themeMode == ThemeMode.dark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: _toggleTheme,
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: AnimationService.instance.reducedMotion,
            builder: (context, reducedMotion, _) {
              return IconButton(
                tooltip: reducedMotion
                    ? 'Reduced motion is on'
                    : 'Motion and visual settings',
                onPressed: _openMotionSettings,
                icon: Icon(
                  reducedMotion
                      ? Icons.motion_photos_off
                      : Icons.tune,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Open Game Hub',
            onPressed: _openGameHub,
            icon: const Icon(Icons.grid_view_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<ScenarioLoadResult>(
          future: _scenarioFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return EmptyState(
                icon: Icons.cloud_off,
                title: 'Scenarios are unavailable',
                message:
                    'Career Chaos Academy could not load the scenario files. Please check the asset configuration and try again.',
                actionLabel: 'Retry',
                onActionPressed: _reloadScenarios,
              );
            }

            final result = snapshot.data;
            if (result == null || !result.hasScenarios) {
              return EmptyState(
                icon: Icons.hourglass_empty,
                title: 'No playable scenarios found',
                message:
                    'The app started safely, but no valid JSON scenario chapters were loaded.',
                actionLabel: 'Reload Scenarios',
                onActionPressed: _reloadScenarios,
              );
            }

            return ValueListenableBuilder<Map<String, RoleProgressModel>>(
              valueListenable: ProgressService.instance.progressByRole,
              builder: (context, _, __) {
                final columns = ResponsiveLayout.roleGridColumns(context);
                final aspectRatio = ResponsiveLayout.roleCardAspectRatio(context);

                return ResponsiveContent(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: ResponsiveLayout.pagePadding(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFFFF4D8D)
                                        .withOpacity(0.34),
                                  ),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: <Color>[
                                      Color(0xFF32152F),
                                      Color(0xFF17172B),
                                      Color(0xFF090B14),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF982F61)
                                          .withOpacity(0.20),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -16,
                                      top: -20,
                                      child: Icon(
                                        Icons.sports_esports_rounded,
                                        size: 150,
                                        color: Colors.white.withOpacity(0.045),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            color: const Color(0xFFFF4D8D)
                                                .withOpacity(0.14),
                                            border: Border.all(
                                              color: const Color(0xFFFF4D8D)
                                                  .withOpacity(0.34),
                                            ),
                                          ),
                                          child: const Text(
                                            'CINEMATIC CAREER SIMULATOR',
                                            style: TextStyle(
                                              color: Color(0xFFFF80AD),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'Choose Your Career Chaos',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Enter a role, survive realistic missions, play skill challenges, and build your career rank.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: Colors.white70,
                                                height: 1.35,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: const [
                                            _HeroStatChip(
                                              icon: Icons.movie_filter,
                                              label: 'Cinematic stories',
                                            ),
                                            _HeroStatChip(
                                              icon: Icons.videogame_asset,
                                              label: 'Flame challenges',
                                            ),
                                            _HeroStatChip(
                                              icon: Icons.emoji_events,
                                              label: 'Ranks & badges',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ScenarioErrorBanner(errors: result.errors),
                              const SizedBox(height: 20),
                              const RankProgressCard(),
                              const SizedBox(height: 12),
                              const ScoreCard(),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: ResponsiveLayout.pagePadding(context).copyWith(
                          top: 0,
                        ),
                        sliver: SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: aspectRatio,
                          ),
                          itemCount: result.roles.length,
                          itemBuilder: (context, index) {
                            final roleScenario = result.roles[index];
                            final progressPercent = ProgressService.instance
                                .progressPercent(roleScenario);

                            return RoleCard(
                              roleScenario: roleScenario,
                              progressPercent: progressPercent,
                              onTap: () {
                                Navigator.of(context).push(
                                  AnimationService.instance.motionRoute<void>(
                                    settings: const RouteSettings(
                                      name: AppRoutes.chapterList,
                                    ),
                                    transition: MotionRouteTransition.slideLeft,
                                    builder: (_) => ChapterListScreen(
                                      roleScenario: roleScenario,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
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

class _GameHubAction {
  const _GameHubAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;
  final WidgetBuilder builder;
}

class _GameHubActionCard extends StatelessWidget {
  const _GameHubActionCard({
    required this.action,
    required this.onTap,
  });

  final _GameHubAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.055),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                const Color(0xFF982F61).withOpacity(0.18),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: const Color(0xFFFF4D8D).withOpacity(0.14),
                ),
                child: Icon(
                  action.icon,
                  color: const Color(0xFFFF80AD),
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                      height: 1.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.065),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
