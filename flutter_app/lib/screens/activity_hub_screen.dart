import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../services/animation_service.dart';
import '../services/progress_service.dart';
import '../widgets/empty_state.dart';
import 'activity_play_screen.dart';

class ActivityHubScreen extends StatefulWidget {
  const ActivityHubScreen({super.key});

  @override
  State<ActivityHubScreen> createState() => _ActivityHubScreenState();
}

class _ActivityHubScreenState extends State<ActivityHubScreen> {
  late Future<ActivityLoadResult> _future;

  @override
  void initState() {
    super.initState();
    _future = ActivityService.instance.loadActivities();
  }

  void _reload() {
    setState(() {
      _future = ActivityService.instance.loadActivities();
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'daily_challenge':
        return Icons.today;
      case 'boss_battle':
        return Icons.sports_martial_arts;
      case 'bug_hunt':
        return Icons.bug_report;
      case 'data_cleanup_race':
        return Icons.table_chart;
      case 'role_quiz':
        return Icons.quiz;
      case 'ethical_dilemma':
        return Icons.balance;
      case 'client_negotiation':
        return Icons.handshake;
      default:
        return Icons.extension;
    }
  }

  String _labelFor(String type) => type
      .split('_')
      .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  String _timerLabel(ActivityModel activity) {
    return activity.isTimed ? '${activity.durationSeconds}s timer' : 'No timer';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Hub')),
      body: FutureBuilder<ActivityLoadResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data;
          if (snapshot.hasError || result == null || !result.hasActivities) {
            return EmptyState(
              icon: Icons.extension_off,
              title: 'Activities unavailable',
              message: 'The activity catalog could not be loaded safely.',
              actionLabel: 'Retry',
              onActionPressed: _reload,
            );
          }

          return ValueListenableBuilder<ActivityStreakModel>(
            valueListenable: ProgressService.instance.activityStreak,
            builder: (context, streak, _) {
              return ResponsiveContent(
                child: ListView(
                  padding: ResponsiveLayout.pagePadding(context),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            child: const Icon(Icons.local_fire_department),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Repeatable Learning Activities',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 6),
                                Text('Current streak: ${streak.currentStreak} • Best: ${streak.longestStreak}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final activity in result.activities) ...[
                      Card(
                        elevation: 0,
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(_iconFor(activity.type))),
                          title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                            '${_labelFor(activity.type)} • ${activity.difficulty} • ${_timerLabel(activity)}\n${activity.description}',
                          ),
                          isThreeLine: true,
                          trailing: activity.weeklyPlaceholder
                              ? const Chip(label: Text('Soon'))
                              : Text('+${activity.rewardXp} XP'),
                          onTap: () {
                            Navigator.of(context).push(
                              AnimationService.instance.motionRoute<void>(
                                builder: (_) => ActivityPlayScreen(activity: activity),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 20),
                    ValueListenableBuilder<List<ActivityHistoryModel>>(
                      valueListenable: ProgressService.instance.activityHistory,
                      builder: (context, history, __) {
                        if (history.isEmpty) {
                          return const Text('No activity history yet. Play one activity to start your streak.');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recent Activity History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            for (final item in history.take(5))
                              ListTile(
                                dense: true,
                                leading: Icon(item.isSuccess ? Icons.check_circle : Icons.warning, color: item.isSuccess ? Colors.green : scheme.error),
                                title: Text(item.title),
                                subtitle: Text('${item.isSuccess ? 'Completed' : 'Attempted'} • +${item.xpEarned} XP • streak ${item.streakAfter}'),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
