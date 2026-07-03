import 'package:flutter/material.dart';

import '../models/team_session_model.dart';

class TeamDebriefScreen extends StatelessWidget {
  final TeamSessionModel session;

  const TeamDebriefScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final debrief = session.debrief;
    final score = debrief?.scoreBreakdown ?? session.teamScore;
    return Scaffold(
      appBar: AppBar(title: const Text('Team Debrief')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.scenario.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(debrief?.summary ?? 'The team simulation is complete.'),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        '${debrief?.total ?? score.total}/100',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ScoreTile(label: 'Collaboration', value: score.collaboration, icon: Icons.groups),
            _ScoreTile(label: 'Communication', value: score.communication, icon: Icons.forum),
            _ScoreTile(label: 'Speed', value: score.speed, icon: Icons.timer),
            _ScoreTile(label: 'Accuracy', value: score.accuracy, icon: Icons.fact_check),
            _ScoreTile(label: 'Ethics', value: score.ethics, icon: Icons.verified_user),
            const SizedBox(height: 12),
            if (session.decisions.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Key Team Moments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      for (final decision in session.decisions)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.alt_route),
                          title: Text('${decision.displayName} • ${decision.roleId}'),
                          subtitle: Text('${decision.choiceText}\n${decision.outcomeSummary}'),
                          isThreeLine: true,
                        ),
                    ],
                  ),
                ),
              ),
            if ((debrief?.recommendations ?? const <String>[]).isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Improvement Plan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      for (final recommendation in debrief!.recommendations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(recommendation)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _ScoreTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: value.clamp(0, 100) / 100),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$value', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
