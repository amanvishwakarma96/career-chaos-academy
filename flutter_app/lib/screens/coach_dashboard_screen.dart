import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/career_coach/user_skill_profile_model.dart';
import '../models/role_scenario_model.dart';
import '../services/career_coach_service.dart';
import '../services/progress_service.dart';
import '../services/scenario_service.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  late Future<_CoachDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CoachDashboardData> _load() async {
    final scenarios = await ScenarioService.instance.loadScenarios();
    final styles = await CareerCoachService.instance.loadCoachStyles();
    final roadmaps = await CareerCoachService.instance.loadCareerRoadmaps();
    final state = await CareerCoachService.instance.refreshAndSaveCoachState(
      roles: scenarios.roles,
    );
    return _CoachDashboardData(
      state: state,
      styles: styles,
      roadmaps: roadmaps,
      roles: scenarios.roles,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _updateStyle(String styleId) async {
    final current = ProgressService.instance.careerCoachState.value;
    await ProgressService.instance.updateCareerCoachState(
      current.copyWith(
        preference: current.preference.copyWith(selectedStyleId: styleId),
        updatedAt: DateTime.now(),
      ),
    );
    _reload();
  }

  Future<void> _toggleRoast(bool enabled) async {
    final current = ProgressService.instance.careerCoachState.value;
    await ProgressService.instance.updateCareerCoachState(
      current.copyWith(
        preference: current.preference.copyWith(roastModeEnabled: enabled),
        updatedAt: DateTime.now(),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Career Coach'),
        actions: [
          IconButton(
            tooltip: 'Refresh coach plan',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_CoachDashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology_alt, size: 48),
                      const SizedBox(height: 12),
                      const Text('Coach is warming up the whiteboard.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _reload,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final data = snapshot.data!;
            final state = data.state;
            final profile = state.skillProfile;
            final plan = state.weeklyPlan;
            final selectedStyle = data.styles.firstWhere(
              (style) => style.id == state.preference.selectedStyleId,
              orElse: () => data.styles.first,
            );

            return ResponsiveContent(
              child: ListView(
                padding: ResponsiveLayout.pagePadding(context),
                children: [
                  _HeroCard(
                    title: 'Your Career Coach',
                    subtitle: selectedStyle.name,
                    body: state.lastAdvice.isEmpty
                        ? 'Complete chapters and activities to unlock richer coaching.'
                        : state.lastAdvice,
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Mentor Style',
                    child: Column(
                      children: [
                        for (final style in data.styles)
                          RadioListTile<String>(
                            value: style.id,
                            groupValue: state.preference.selectedStyleId,
                            onChanged: (value) {
                              if (value != null) _updateStyle(value);
                            },
                            title: Text(style.name),
                            subtitle: Text(style.description),
                          ),
                        SwitchListTile(
                          title: const Text('Roast mode'),
                          subtitle: const Text('Optional. Decision-focused, never abusive.'),
                          value: state.preference.roastModeEnabled,
                          onChanged: _toggleRoast,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileCard(profile: profile),
                  const SizedBox(height: 16),
                  FutureBuilder<List<String>>(
                    future: CareerCoachService.instance.weakSkillNodeRecommendations(
                      snapshot: ProgressService.instance.currentSnapshot(),
                    ),
                    builder: (context, skillSnapshot) {
                      final items = skillSnapshot.data ?? const <String>[];
                      if (items.isEmpty) return const SizedBox.shrink();
                      return _SectionCard(
                        title: 'Weak Skill Nodes',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('• $item'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: plan.title,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Chips(label: 'Focus', items: plan.focusAreas),
                        const SizedBox(height: 8),
                        for (final step in plan.dailySteps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(step)),
                              ],
                            ),
                          ),
                        const Divider(),
                        Text('Next activity: ${plan.nextActivityId.isEmpty ? 'Complete any activity' : plan.nextActivityId}'),
                        if (plan.nextRoleId.isNotEmpty) Text('Next role: ${plan.nextRoleId}'),
                        if (plan.nextChapterId.isNotEmpty) Text('Next chapter: ${plan.nextChapterId}'),
                        if (plan.safetyNote.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            plan.safetyNote,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Career Roadmaps',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final roadmap in data.roadmaps.take(8)) ...[
                          Text(
                            roadmap.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          for (final step in roadmap.steps.take(3))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• $step'),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CoachDashboardData {
  final CareerCoachStateModel state;
  final List<CoachMentorStyleModel> styles;
  final List<CareerRoadmapModel> roadmaps;
  final List<RoleScenarioModel> roles;

  const _CoachDashboardData({
    required this.state,
    required this.styles,
    required this.roadmaps,
    required this.roles,
  });
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String body;

  const _HeroCard({required this.title, required this.subtitle, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(body),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserSkillProfileModel profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Skill Profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Chips(label: 'Top strengths', items: profile.topStrengths),
          const SizedBox(height: 10),
          _Chips(label: 'Weak areas', items: profile.weakAreas),
          const SizedBox(height: 10),
          Text('Completed chapters: ${profile.completedChapters}'),
          Text('Completed activities: ${profile.completedActivities}'),
          Text('Failed mini-games: ${profile.failedMiniGames}'),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  final String label;
  final List<String> items;

  const _Chips({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    final values = items.isEmpty ? const <String>['Keep playing to learn more'] : items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in values)
              Chip(label: Text(item.replaceAll('_', ' '))),
          ],
        ),
      ],
    );
  }
}
