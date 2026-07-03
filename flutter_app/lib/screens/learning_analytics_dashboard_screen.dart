import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/learning_analytics_model.dart';
import '../services/learning_analytics_service.dart';
import '../widgets/info_panel.dart';

class LearningAnalyticsDashboardScreen extends StatefulWidget {
  const LearningAnalyticsDashboardScreen({super.key});

  @override
  State<LearningAnalyticsDashboardScreen> createState() => _LearningAnalyticsDashboardScreenState();
}

class _LearningAnalyticsDashboardScreenState extends State<LearningAnalyticsDashboardScreen> {
  late Future<_AnalyticsViewState> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AnalyticsViewState> _load() async {
    final settings = await LearningAnalyticsService.instance.loadSettings();
    final personal = await LearningAnalyticsService.instance.loadPersonalDashboard();
    final admin = await LearningAnalyticsService.instance.loadAdminDashboard();
    return _AnalyticsViewState(settings: settings, personal: personal, admin: admin);
  }

  Future<void> _setAnalyticsEnabled(bool enabled) async {
    final current = await LearningAnalyticsService.instance.loadSettings();
    await LearningAnalyticsService.instance.saveSettings(current.copyWith(enabled: enabled));
    setState(() => _future = _load());
  }

  Future<void> _setAggregateSharing(bool enabled) async {
    final current = await LearningAnalyticsService.instance.loadSettings();
    await LearningAnalyticsService.instance.saveSettings(current.copyWith(shareAggregateWithAdmin: enabled));
    setState(() => _future = _load());
  }

  Future<void> _seedDemoEvents() async {
    await LearningAnalyticsService.instance.trackChapterStarted(roleId: 'developer', chapterId: 'developer_login_button_disaster');
    await LearningAnalyticsService.instance.trackChoiceSelected(
      roleId: 'developer',
      chapterId: 'developer_login_button_disaster',
      choiceId: 'safe_debug_first',
      scoreDelta: const <String, dynamic>{'skill': 2, 'ethics': 1, 'communication': 1, 'chaos': -1},
    );
    await LearningAnalyticsService.instance.trackMiniGameAttempt(
      roleId: 'developer',
      chapterId: 'developer_login_button_disaster',
      miniGameId: 'developer_login_button_code_fix',
      passed: true,
      timeSpentSeconds: 95,
      scoreDelta: const <String, dynamic>{'skill': 3, 'discipline': 2},
    );
    await LearningAnalyticsService.instance.trackChapterCompleted(
      roleId: 'developer',
      chapterId: 'developer_login_button_disaster',
      timeSpentSeconds: 180,
      scoreDelta: const <String, dynamic>{'skill': 4, 'discipline': 2, 'ethics': 2, 'communication': 2, 'chaos': -2},
    );
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Learning Analytics'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.person_search), text: 'My Progress'),
              Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admin Aggregate'),
            ],
          ),
        ),
        body: FutureBuilder<_AnalyticsViewState>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('Analytics dashboard is unavailable.'));
            }
            return TabBarView(
              children: <Widget>[
                _PersonalAnalyticsTab(
                  state: data,
                  onAnalyticsEnabledChanged: _setAnalyticsEnabled,
                  onAggregateSharingChanged: _setAggregateSharing,
                  onSeedDemoPressed: _seedDemoEvents,
                ),
                _AdminAnalyticsTab(dashboard: data.admin),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PersonalAnalyticsTab extends StatelessWidget {
  final _AnalyticsViewState state;
  final ValueChanged<bool> onAnalyticsEnabledChanged;
  final ValueChanged<bool> onAggregateSharingChanged;
  final VoidCallback onSeedDemoPressed;

  const _PersonalAnalyticsTab({
    required this.state,
    required this.onAnalyticsEnabledChanged,
    required this.onAggregateSharingChanged,
    required this.onSeedDemoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final dashboard = state.personal;
    final summary = dashboard.summary;
    return SafeArea(
      child: ResponsiveContent(
        child: ListView(
          padding: ResponsiveLayout.pagePadding(context),
          children: <Widget>[
            InfoPanel(
              title: 'Privacy-safe learning progress',
              body: 'Tracks chapter starts/completions, choices, mini-game attempts, time spent, role progress, and skill improvement. Free-text answers, names, emails, phone numbers, passwords, tokens, and messages are filtered before storage.',
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: state.settings.enabled,
              onChanged: onAnalyticsEnabledChanged,
              title: const Text('Enable analytics'),
              subtitle: const Text('Turn this off to stop new analytics events from being logged.'),
            ),
            SwitchListTile(
              value: state.settings.shareAggregateWithAdmin,
              onChanged: state.settings.enabled ? onAggregateSharingChanged : null,
              title: const Text('Share anonymized aggregate data'),
              subtitle: const Text('Admin dashboard receives aggregate counts only, not raw user IDs or personal text.'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: state.settings.enabled ? onSeedDemoPressed : null,
              icon: const Icon(Icons.add_chart),
              label: const Text('Log demo analytics event set'),
            ),
            const SizedBox(height: 16),
            _SummaryGrid(summary: summary),
            const SizedBox(height: 16),
            _RoleProgressSection(roles: summary.roleProgress.values.toList(growable: false)),
            const SizedBox(height: 16),
            _SkillImprovementSection(skills: summary.skillImprovement),
            const SizedBox(height: 16),
            _RecentEventsSection(events: dashboard.recentEvents),
            const SizedBox(height: 16),
            InfoPanel(
              title: 'Performance guardrail',
              body: '${dashboard.performance['appPerformanceImpact'] ?? 'low'} • Events are capped and summarized in a single pass.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminAnalyticsTab extends StatelessWidget {
  final AdminAnalyticsDashboardModel dashboard;

  const _AdminAnalyticsTab({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ResponsiveContent(
        child: ListView(
          padding: ResponsiveLayout.pagePadding(context),
          children: <Widget>[
            InfoPanel(
              title: 'Admin aggregate dashboard',
              body: 'Shows event counts, aggregate role progress, total learning time, and skill trends without exposing raw user IDs, names, emails, answers, messages, or unnecessary personal data.',
            ),
            const SizedBox(height: 16),
            _SummaryGrid(summary: dashboard.summary),
            const SizedBox(height: 16),
            _MetricMapCard(title: 'Events by type', values: dashboard.eventCountsByType),
            const SizedBox(height: 16),
            _MetricMapCard(title: 'Events by role', values: dashboard.roleCounts),
            const SizedBox(height: 16),
            _RoleProgressSection(roles: dashboard.summary.roleProgress.values.toList(growable: false)),
            const SizedBox(height: 16),
            _SkillImprovementSection(skills: dashboard.summary.skillImprovement),
            const SizedBox(height: 16),
            InfoPanel(
              title: 'Privacy policy applied',
              body: 'Raw user IDs exposed: ${dashboard.privacy['rawUserIdsExposed'] == true ? 'yes' : 'no'} • Aggregate only: ${dashboard.privacy['aggregateOnly'] == true ? 'yes' : 'yes'}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final LearningAnalyticsSummaryModel summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final minutes = (summary.totalTimeSpentSeconds / 60).round();
    final items = <_MetricItem>[
      _MetricItem('Events', summary.totalEvents.toString(), Icons.track_changes),
      _MetricItem('Started', summary.totalChapterStarts.toString(), Icons.play_circle),
      _MetricItem('Completed', summary.totalChapterCompletions.toString(), Icons.check_circle),
      _MetricItem('Choices', summary.totalChoiceSelections.toString(), Icons.call_split),
      _MetricItem('Mini-games', summary.totalMiniGameAttempts.toString(), Icons.videogame_asset),
      _MetricItem('Minutes', minutes.toString(), Icons.timer),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) => _MetricCard(item: item)).toList(growable: false),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricItem item;

  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(item.icon),
              const SizedBox(height: 8),
              Text(item.value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              Text(item.label),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleProgressSection extends StatelessWidget {
  final List<RoleAnalyticsProgressModel> roles;

  const _RoleProgressSection({required this.roles});

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return const InfoPanel(title: 'Role progress', body: 'No role analytics yet. Start a chapter or log demo events.');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Role progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...roles.map((role) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(role.roleId, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: role.progressPercent / 100),
                      const SizedBox(height: 4),
                      Text('${role.progressPercent}% • starts ${role.chapterStarts} • completed ${role.chapterCompletions} • choices ${role.choices} • mini-games ${role.miniGameAttempts}'),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _SkillImprovementSection extends StatelessWidget {
  final Map<String, int> skills;

  const _SkillImprovementSection({required this.skills});

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return const InfoPanel(title: 'Skill improvement', body: 'No skill improvement events yet.');
    }
    return _MetricMapCard(title: 'Skill improvement', values: skills);
  }
}

class _MetricMapCard extends StatelessWidget {
  final String title;
  final Map<String, int> values;

  const _MetricMapCard({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (values.isEmpty)
              const Text('No aggregate data yet.')
            else
              ...values.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: Text(entry.key)),
                        Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _RecentEventsSection extends StatelessWidget {
  final List<LearningAnalyticsEventModel> events;

  const _RecentEventsSection({required this.events});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Recent events', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const Text('No recent events yet.')
            else
              ...events.take(8).map((event) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.analytics),
                    title: Text(event.eventType),
                    subtitle: Text('${event.roleId} ${event.chapterId.isEmpty ? '' : '• ${event.chapterId}'}'),
                    trailing: Text('${event.durationSeconds}s'),
                  )),
          ],
        ),
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;

  const _MetricItem(this.label, this.value, this.icon);
}

class _AnalyticsViewState {
  final LearningAnalyticsSettingsModel settings;
  final PersonalAnalyticsDashboardModel personal;
  final AdminAnalyticsDashboardModel admin;

  const _AnalyticsViewState({required this.settings, required this.personal, required this.admin});
}
