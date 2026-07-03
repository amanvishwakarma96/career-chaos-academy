import 'dart:async';

import 'package:flutter/material.dart';

import '../models/activity_model.dart';
import '../services/activity_service.dart';
import '../services/progress_service.dart';
import '../widgets/motion_feedback_animation.dart';

class ActivityPlayScreen extends StatefulWidget {
  final ActivityModel activity;

  const ActivityPlayScreen({super.key, required this.activity});

  @override
  State<ActivityPlayScreen> createState() => _ActivityPlayScreenState();
}

class _ActivityPlayScreenState extends State<ActivityPlayScreen> {
  final Set<String> _selectedAnswers = <String>{};
  Timer? _timer;
  late int _secondsRemaining;
  ActivityEvaluationResult? _evaluation;
  ActivityCompletionResultModel? _completion;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.activity.durationSeconds;
    if (widget.activity.isTimed && !widget.activity.weeklyPlaceholder) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_secondsRemaining <= 1) {
          timer.cancel();
          _submit();
        } else {
          setState(() => _secondsRemaining -= 1);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle(String option) {
    if (_evaluation != null) return;
    setState(() {
      if (widget.activity.allowsMultipleSelection) {
        if (!_selectedAnswers.remove(option)) {
          _selectedAnswers.add(option);
        }
      } else {
        _selectedAnswers
          ..clear()
          ..add(option);
      }
    });
  }

  Future<void> _submit() async {
    if (_evaluation != null) return;
    _timer?.cancel();
    final evaluation = ActivityService.instance.evaluate(
      activity: widget.activity,
      selectedAnswers: _selectedAnswers,
      secondsRemaining: _secondsRemaining,
    );
    final completion = await ProgressService.instance.recordActivityResult(
      activity: widget.activity,
      isSuccess: evaluation.isSuccess,
      score: evaluation.score,
      xpEarned: evaluation.xpEarned,
      feedback: evaluation.feedback,
    );
    if (!mounted) return;
    setState(() {
      _evaluation = evaluation;
      _completion = completion;
    });
  }

  void _replay() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ActivityPlayScreen(activity: widget.activity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final evaluation = _evaluation;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(activity.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Chip(label: Text(activity.type.replaceAll('_', ' '))),
                const SizedBox(width: 8),
                Chip(label: Text(activity.difficulty)),
                const Spacer(),
                if (activity.isTimed)
                  Chip(
                    avatar: const Icon(Icons.timer, size: 18),
                    label: Text('${evaluation == null ? _secondsRemaining : 0}s'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(activity.description, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 14),
            Text(activity.prompt, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            for (final option in activity.options) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _selectedAnswers.contains(option) ? scheme.primary : scheme.outlineVariant,
                    width: _selectedAnswers.contains(option) ? 2 : 1,
                  ),
                  color: _selectedAnswers.contains(option) ? scheme.primaryContainer : scheme.surface,
                ),
                child: CheckboxListTile(
                  value: _selectedAnswers.contains(option),
                  onChanged: (_) => _toggle(option),
                  title: Text(option),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (evaluation == null)
              FilledButton.icon(
                onPressed: _selectedAnswers.isEmpty ? null : _submit,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Submit Activity'),
              )
            else
              Card(
                elevation: 0,
                color: evaluation.isSuccess ? Colors.green.withOpacity(0.12) : scheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MotionFeedbackAnimation(
                        type: evaluation.isSuccess ? MotionFeedbackType.success : MotionFeedbackType.failure,
                        size: 100,
                      ),
                      Text(
                        evaluation.isSuccess ? 'Activity Completed!' : 'Funny Failure, Useful Lesson',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(evaluation.feedback, textAlign: TextAlign.center),
                      const Divider(height: 24),
                      Text('Score: ${evaluation.score}/100 • XP: +${evaluation.xpEarned} • Streak: ${_completion?.streak.currentStreak ?? 0}'),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Learning point', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      Align(alignment: Alignment.centerLeft, child: Text(activity.learningPoint)),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Practical takeaway', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      Align(alignment: Alignment.centerLeft, child: Text(activity.practicalTakeaway)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _replay,
                            icon: const Icon(Icons.replay),
                            label: const Text('Replay'),
                          ),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.check),
                            label: const Text('Back to Hub'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
