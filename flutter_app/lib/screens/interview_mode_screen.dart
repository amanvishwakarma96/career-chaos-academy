import 'package:flutter/material.dart';

import '../models/interview_question_model.dart';
import '../models/role_scenario_model.dart';
import '../services/device_user_service.dart';
import '../services/interview_service.dart';
import '../services/scenario_service.dart';

class InterviewModeScreen extends StatefulWidget {
  const InterviewModeScreen({super.key});

  @override
  State<InterviewModeScreen> createState() => _InterviewModeScreenState();
}

class _InterviewModeScreenState extends State<InterviewModeScreen> {
  late Future<ScenarioLoadResult> _rolesFuture;
  RoleScenarioModel? _selectedRole;
  InterviewQuestionBankResult? _bank;
  InterviewReadinessReportModel? _report;
  final Map<String, TextEditingController> _answerControllers = <String, TextEditingController>{};
  final Map<String, InterviewAnswerFeedbackModel> _feedbackByQuestion = <String, InterviewAnswerFeedbackModel>{};
  String _userId = '';
  String _message = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rolesFuture = ScenarioService.instance.loadScenarios();
    _loadUser();
  }

  @override
  void dispose() {
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUser() async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    if (!mounted) return;
    setState(() => _userId = userId);
  }

  Future<void> _selectRole(RoleScenarioModel roleScenario) async {
    setState(() {
      _selectedRole = roleScenario;
      _bank = null;
      _report = null;
      _message = '';
      _feedbackByQuestion.clear();
      for (final controller in _answerControllers.values) {
        controller.dispose();
      }
      _answerControllers.clear();
      _isLoading = true;
    });
    try {
      final bank = await InterviewService.instance.loadQuestionsForRole(roleScenario.role.id);
      if (!mounted) return;
      setState(() {
        _bank = bank;
        for (final question in bank.questions) {
          _answerControllers[question.id] = TextEditingController();
        }
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer(InterviewQuestionModel question) async {
    final answer = _answerControllers[question.id]?.text.trim() ?? '';
    if (answer.isEmpty) {
      setState(() => _message = 'Write an answer before requesting AI feedback.');
      return;
    }
    setState(() {
      _isLoading = true;
      _message = '';
    });
    try {
      final feedback = await InterviewService.instance.generateFeedback(question: question, answer: answer);
      if (!mounted) return;
      setState(() {
        _feedbackByQuestion[question.id] = feedback;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isLoading = false;
      });
    }
  }

  void _retryQuestion(InterviewQuestionModel question) {
    _answerControllers[question.id]?.clear();
    setState(() {
      _feedbackByQuestion.remove(question.id);
      _report = null;
      _message = 'Retry started for ${question.roundLabel}. Use the tips and improve your answer.';
    });
  }

  Future<void> _saveReport() async {
    final role = _selectedRole;
    final bank = _bank;
    if (role == null || bank == null) return;
    if (_feedbackByQuestion.length < bank.questions.length) {
      setState(() => _message = 'Complete all rounds before saving the readiness report.');
      return;
    }
    setState(() {
      _isLoading = true;
      _message = '';
    });
    final orderedFeedback = bank.questions
        .map((question) => _feedbackByQuestion[question.id])
        .whereType<InterviewAnswerFeedbackModel>()
        .toList(growable: false);
    final report = InterviewService.instance.buildReport(
      userId: _userId.isEmpty ? 'local-user' : _userId,
      roleId: role.role.id,
      roleName: role.role.name,
      feedbackItems: orderedFeedback,
    );
    try {
      final saved = await InterviewService.instance.saveReport(report);
      if (!mounted) return;
      setState(() {
        _report = saved;
        _isLoading = false;
        _message = 'Interview readiness report saved.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview Readiness')),
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder<ScenarioLoadResult>(
              future: _rolesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null || snapshot.data!.roles.isEmpty) {
                  return const Center(child: Text('Unable to load interview roles.'));
                }
                final roles = snapshot.data!.roles;
                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const _HeaderCard(),
                    const SizedBox(height: 14),
                    _RolePickerCard(
                      roles: roles,
                      selectedRoleId: _selectedRole?.role.id,
                      onSelected: _selectRole,
                    ),
                    const SizedBox(height: 14),
                    if (_bank != null) _RubricCard(rubric: _bank!.rubric),
                    if (_bank != null) const SizedBox(height: 14),
                    if (_bank != null)
                      for (final question in _bank!.questions) ...[
                        _QuestionCard(
                          question: question,
                          controller: _answerControllers[question.id]!,
                          feedback: _feedbackByQuestion[question.id],
                          onSubmit: () => _submitAnswer(question),
                          onRetry: () => _retryQuestion(question),
                        ),
                        const SizedBox(height: 12),
                      ],
                    if (_bank != null)
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _saveReport,
                        icon: const Icon(Icons.description),
                        label: const Text('Save Interview Readiness Report'),
                      ),
                    if (_report != null) ...[
                      const SizedBox(height: 14),
                      _ReportCard(report: _report!),
                    ],
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(_message),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            if (_isLoading)
              Container(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interview & Job Readiness Mode',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text('Select a career role, answer technical, behavioral, and situation rounds, then use AI-style feedback to improve before saving your readiness report.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VoiceSettingsScreen(interviewPrototype: true),
                ),
              );
            },
            icon: const Icon(Icons.mic_external_on),
            label: const Text('Try voice interview prototype'),
          ),
        ],
      ),
    );
  }
}

class _RolePickerCard extends StatelessWidget {
  final List<RoleScenarioModel> roles;
  final String? selectedRoleId;
  final ValueChanged<RoleScenarioModel> onSelected;

  const _RolePickerCard({required this.roles, required this.selectedRoleId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select interview role', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final roleScenario in roles)
                  ChoiceChip(
                    label: Text(roleScenario.role.name),
                    selected: selectedRoleId == roleScenario.role.id,
                    onSelected: (_) => onSelected(roleScenario),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RubricCard extends StatelessWidget {
  final Map<String, String> rubric;

  const _RubricCard({required this.rubric});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scoring Rubric', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final entry in rubric.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• ${_title(entry.key)}: ${entry.value}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final InterviewQuestionModel question;
  final TextEditingController controller;
  final InterviewAnswerFeedbackModel? feedback;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;

  const _QuestionCard({
    required this.question,
    required this.controller,
    required this.feedback,
    required this.onSubmit,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final feedback = this.feedback;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(question.roundLabel)),
                Chip(label: Text(question.difficulty)),
                for (final tag in question.skillTags.take(3)) Chip(label: Text(tag)),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.prompt, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              enabled: feedback == null,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Your answer',
                hintText: 'Use STAR format, mention evidence, stakeholders, risks, and follow-up.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: feedback == null ? onSubmit : null,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate AI Feedback'),
                ),
                const SizedBox(width: 8),
                if (feedback != null)
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry & Improve'),
                  ),
              ],
            ),
            if (feedback != null) ...[
              const SizedBox(height: 14),
              _FeedbackPanel(feedback: feedback),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  final InterviewAnswerFeedbackModel feedback;

  const _FeedbackPanel({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score: ${feedback.score}/100', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: feedback.score.clamp(0, 100) / 100),
          const SizedBox(height: 8),
          Text(feedback.aiSummary),
          const SizedBox(height: 10),
          Text('Rubric', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in feedback.rubricScores.entries) Chip(label: Text('${_title(entry.key)} ${entry.value}')),
            ],
          ),
          const SizedBox(height: 10),
          Text('Strengths', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          for (final item in feedback.strengths) Text('• $item'),
          const SizedBox(height: 10),
          Text('Improvement tips', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          for (final item in feedback.improvementTips) Text('• $item'),
          if (feedback.retryPrompt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(feedback.retryPrompt, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final InterviewReadinessReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved Readiness Report', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('${report.roleName} • ${report.readinessLevel}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: report.totalScore.clamp(0, 100) / 100),
            const SizedBox(height: 6),
            Text('Total score: ${report.totalScore}/100'),
            const SizedBox(height: 12),
            Text('Top strengths', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            for (final item in report.strengths) Text('• $item'),
            const SizedBox(height: 10),
            Text('Next steps', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            for (final item in report.nextSteps) Text('• $item'),
          ],
        ),
      ),
    );
  }
}

String _title(String value) {
  if (value.isEmpty) return value;
  final spaced = value.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}');
  return spaced[0].toUpperCase() + spaced.substring(1);
}
