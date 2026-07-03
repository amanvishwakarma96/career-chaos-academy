import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/mentor/mentor_model.dart';
import '../services/animation_service.dart';
import '../services/mentor_service.dart';
import '../services/progress_service.dart';
import '../widgets/info_panel.dart';

class MentorSelectionScreen extends StatefulWidget {
  const MentorSelectionScreen({super.key});

  @override
  State<MentorSelectionScreen> createState() => _MentorSelectionScreenState();
}

class _MentorSelectionScreenState extends State<MentorSelectionScreen> {
  late Future<List<MentorModel>> _mentorsFuture;

  @override
  void initState() {
    super.initState();
    _mentorsFuture = MentorService.instance.loadMentors();
  }

  Future<void> _selectMentor(MentorPreferenceModel current, String mentorId) async {
    await ProgressService.instance.updateMentorPreference(
      current.copyWith(selectedMentorId: mentorId),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mentor preference saved.')),
    );
  }

  Future<void> _toggleRoast(MentorPreferenceModel current, bool enabled) async {
    await ProgressService.instance.updateMentorPreference(
      current.copyWith(roastModeEnabled: enabled),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Mentor')),
      body: SafeArea(
        child: FutureBuilder<List<MentorModel>>(
          future: _mentorsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final mentors = snapshot.data ?? const <MentorModel>[];
            return ValueListenableBuilder<MentorPreferenceModel>(
              valueListenable: ProgressService.instance.mentorPreference,
              builder: (context, preference, _) {
                return ResponsiveContent(
                  child: ListView(
                    padding: ResponsiveLayout.pagePadding(context),
                    children: [
                      InfoPanel(
                        title: 'Choose your mentor style',
                        body:
                            'Mentors give personalized chapter feedback based on your score, weak areas, choices, and behavior. Feedback is always safe and encouraging.',
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: SwitchListTile(
                          title: const Text('Roast mode'),
                          subtitle: const Text(
                            'Optional light jokes about the decision pattern. Never abusive and can be turned off anytime.',
                          ),
                          value: preference.roastModeEnabled,
                          onChanged: (value) => _toggleRoast(preference, value),
                          secondary: const Icon(Icons.theater_comedy),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final mentor in mentors) ...[
                        _MentorCard(
                          mentor: mentor,
                          selected: mentor.id == preference.selectedMentorId,
                          onSelect: () => _selectMentor(preference, mentor.id),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 12),
                      FutureBuilder<String>(
                        future: Future<String>.value(
                          MentorService.instance.weeklyProgressSummary(
                            ProgressService.instance.currentSnapshot(),
                          ),
                        ),
                        builder: (context, summary) {
                          return InfoPanel(
                            title: 'Weekly Progress Summary',
                            body: summary.data ?? 'Summary is preparing.',
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
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  final MentorModel mentor;
  final bool selected;
  final VoidCallback onSelect;

  const _MentorCard({
    required this.mentor,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      duration: AnimationService.instance.duration(const Duration(milliseconds: 180)),
      scale: selected ? 1.02 : 1,
      child: Card(
        elevation: selected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(mentor.emoji, style: const TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mentor.name,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(mentor.title),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  ],
                ),
                const SizedBox(height: 12),
                Text(mentor.description),
                if (mentor.strengths.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mentor.strengths
                        .map(
                          (strength) => Chip(
                            label: Text(strength),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (mentor.safetyBoundary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    mentor.safetyBoundary,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
