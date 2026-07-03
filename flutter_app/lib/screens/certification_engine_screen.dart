import 'package:flutter/material.dart';

import '../models/assessment_model.dart';
import '../models/assessment_session_model.dart';
import '../models/role_scenario_model.dart';
import '../services/certification_service.dart';
import '../services/device_user_service.dart';
import '../services/scenario_service.dart';

class CertificationEngineScreen extends StatefulWidget {
  const CertificationEngineScreen({super.key});

  @override
  State<CertificationEngineScreen> createState() => _CertificationEngineScreenState();
}

class _CertificationEngineScreenState extends State<CertificationEngineScreen> {
  late Future<ScenarioLoadResult> _rolesFuture;
  String _userId = '';
  RoleScenarioModel? _selectedRole;
  AssessmentModel? _assessment;
  AssessmentSessionModel? _session;
  AssessmentResultModel? _result;
  CertificateRecordModel? _certificate;
  List<CertificateRecordModel> _savedCertificates = const <CertificateRecordModel>[];
  final Map<String, int> _selectedAnswers = <String, int>{};
  int _practicalScore = 75;
  String _message = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rolesFuture = ScenarioService.instance.loadScenarios();
    _loadUserAndCertificates();
  }

  Future<void> _loadUserAndCertificates() async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    final certificates = await CertificationService.instance.loadCertificates(userId);
    if (!mounted) return;
    setState(() {
      _userId = userId;
      _savedCertificates = certificates;
    });
  }

  Future<void> _selectRole(RoleScenarioModel roleScenario) async {
    setState(() {
      _selectedRole = roleScenario;
      _assessment = null;
      _session = null;
      _result = null;
      _certificate = null;
      _selectedAnswers.clear();
      _message = '';
      _isLoading = true;
    });
    try {
      final assessment = await CertificationService.instance.loadAssessmentForRole(roleScenario.role.id);
      if (!mounted) return;
      setState(() {
        _assessment = assessment;
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

  Future<void> _startAssessment() async {
    final role = _selectedRole;
    if (role == null) return;
    setState(() {
      _isLoading = true;
      _message = '';
      _result = null;
      _certificate = null;
      _selectedAnswers.clear();
    });
    try {
      final started = await CertificationService.instance.startAssessment(
        userId: _userId.isEmpty ? 'local-user' : _userId,
        displayName: 'Career Chaos Learner',
        roleId: role.role.id,
      );
      if (!mounted) return;
      setState(() {
        _assessment = started.assessment;
        _session = started.session;
        _isLoading = false;
        _message = 'Timed assessment started. Complete all role-skill questions and practical score before submitting.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _completeAssessment() async {
    final session = _session;
    final assessment = _assessment;
    if (session == null || assessment == null) return;
    if (_selectedAnswers.length < assessment.questions.length) {
      setState(() => _message = 'Answer all assessment questions before submitting.');
      return;
    }
    setState(() {
      _isLoading = true;
      _message = '';
    });
    try {
      final completed = await CertificationService.instance.completeAssessment(
        session: session,
        assessment: assessment,
        selectedAnswers: _selectedAnswers,
        practicalScore: _practicalScore,
      );
      final certificates = await CertificationService.instance.loadCertificates(session.userId);
      if (!mounted) return;
      setState(() {
        _session = completed.session;
        _assessment = completed.assessment;
        _result = completed.session.result;
        _certificate = completed.certificate;
        _savedCertificates = certificates;
        _isLoading = false;
        _message = completed.session.result?.passed == true
            ? 'Assessment passed. Certificate generated with unique verification ID.'
            : 'Assessment failed. Review improvement tips and retry.';
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
      appBar: AppBar(title: const Text('Certification Engine')),
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
                  return const Center(child: Text('Unable to load certification roles.'));
                }
                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const _CertificationHeaderCard(),
                    const SizedBox(height: 14),
                    _CertificationRolePicker(
                      roles: snapshot.data!.roles,
                      selectedRoleId: _selectedRole?.role.id,
                      onSelected: _selectRole,
                    ),
                    const SizedBox(height: 14),
                    if (_assessment != null)
                      _AssessmentOverviewCard(
                        assessment: _assessment!,
                        session: _session,
                        onStart: _isLoading ? null : _startAssessment,
                      ),
                    if (_session != null && _assessment != null) ...[
                      const SizedBox(height: 14),
                      _TimedSessionCard(session: _session!),
                      const SizedBox(height: 14),
                      for (final question in _assessment!.questions) ...[
                        _AssessmentQuestionCard(
                          question: question,
                          selectedIndex: _selectedAnswers[question.id],
                          enabled: _session!.status == 'in_progress',
                          onSelected: (index) {
                            setState(() {
                              _selectedAnswers[question.id] = index;
                              _result = null;
                              _certificate = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      _PracticalMiniGameCard(
                        practical: _assessment!.practicalMiniGame,
                        score: _practicalScore,
                        enabled: _session!.status == 'in_progress',
                        onChanged: (value) => setState(() => _practicalScore = value),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isLoading || _session!.status != 'in_progress' ? null : _completeAssessment,
                        icon: const Icon(Icons.verified),
                        label: const Text('Submit Final Assessment'),
                      ),
                    ],
                    if (_result != null) ...[
                      const SizedBox(height: 14),
                      _AssessmentResultCard(result: _result!),
                    ],
                    if (_certificate != null) ...[
                      const SizedBox(height: 14),
                      _CertificateCard(certificate: _certificate!),
                    ],
                    if (_savedCertificates.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SavedCertificatesCard(certificates: _savedCertificates),
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

class _CertificationHeaderCard extends StatelessWidget {
  const _CertificationHeaderCard();

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
            Theme.of(context).colorScheme.tertiaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assessment & Certificate Generation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text('Select a role, start a timed final assessment, complete role-specific skill questions and a practical mini-game score. Certificates are generated only after passing.'),
        ],
      ),
    );
  }
}

class _CertificationRolePicker extends StatelessWidget {
  final List<RoleScenarioModel> roles;
  final String? selectedRoleId;
  final ValueChanged<RoleScenarioModel> onSelected;

  const _CertificationRolePicker({required this.roles, required this.selectedRoleId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select certification role', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in roles)
                  ChoiceChip(
                    label: Text(role.role.name),
                    selected: selectedRoleId == role.role.id,
                    onSelected: (_) => onSelected(role),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentOverviewCard extends StatelessWidget {
  final AssessmentModel assessment;
  final AssessmentSessionModel? session;
  final VoidCallback? onStart;

  const _AssessmentOverviewCard({required this.assessment, required this.session, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assessment.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(assessment.description),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${assessment.questions.length} questions')),
                Chip(label: Text('${assessment.timeLimitSeconds ~/ 60} min timed test')),
                Chip(label: Text('${assessment.minimumPassingScore}% pass')),
                Chip(label: Text('${assessment.minimumPracticalScore}% practical gate')),
                Chip(label: Text('${assessment.minimumEthicsScore}% ethics gate')),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: session?.status == 'in_progress' ? null : onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimedSessionCard extends StatelessWidget {
  final AssessmentSessionModel session;

  const _TimedSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final expiresAt = DateTime.tryParse(session.expiresAt);
    final remaining = expiresAt == null ? null : expiresAt.difference(DateTime.now());
    final remainingText = remaining == null
        ? 'Timed session active'
        : remaining.isNegative
            ? 'Time expired'
            : '${remaining.inMinutes}m ${remaining.inSeconds.remainder(60)}s remaining';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.timer),
        title: Text(remainingText),
        subtitle: Text('Session: ${session.id} • Status: ${session.status}'),
      ),
    );
  }
}

class _AssessmentQuestionCard extends StatelessWidget {
  final AssessmentQuestionModel question;
  final int? selectedIndex;
  final bool enabled;
  final ValueChanged<int> onSelected;

  const _AssessmentQuestionCard({required this.question, required this.selectedIndex, required this.enabled, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(question.roundLabel)),
                Chip(label: Text(question.skillName)),
                Chip(label: Text('${question.points} pts')),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.prompt, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (var i = 0; i < question.options.length; i += 1)
              RadioListTile<int>(
                value: i,
                groupValue: selectedIndex,
                onChanged: enabled ? (value) => value == null ? null : onSelected(value) : null,
                title: Text(question.options[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _PracticalMiniGameCard extends StatelessWidget {
  final PracticalMiniGameAssessmentModel practical;
  final int score;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _PracticalMiniGameCard({required this.practical, required this.score, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(practical.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(practical.instructions),
            const SizedBox(height: 10),
            Text('Practical mini-game score: $score / ${practical.maxScore}'),
            Slider(
              value: score.toDouble(),
              min: 0,
              max: practical.maxScore.toDouble(),
              divisions: 20,
              label: '$score',
              onChanged: enabled ? (value) => onChanged(value.round()) : null,
            ),
            Text('Minimum required: ${practical.minimumScore}% • Duration target: ${practical.durationSeconds}s'),
          ],
        ),
      ),
    );
  }
}

class _AssessmentResultCard extends StatelessWidget {
  final AssessmentResultModel result;

  const _AssessmentResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.resultLabel}: ${result.totalScore}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Questions ${result.questionScore}%')),
                Chip(label: Text('Practical ${result.practicalScore}%')),
                for (final entry in result.roundScores.entries) Chip(label: Text('${entry.key}: ${entry.value}%')),
              ],
            ),
            const SizedBox(height: 10),
            for (final tip in result.improvementTips) Text('• $tip'),
          ],
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateRecordModel certificate;

  const _CertificateCard({required this.certificate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Certificate Generated', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Recipient: ${certificate.recipientName}'),
            Text('Role: ${certificate.roleName}'),
            Text('Score: ${certificate.totalScore}%'),
            Text('Verification ID: ${certificate.verificationId}'),
            Text('PDF: ${certificate.pdfPath.isEmpty ? 'Available from backend certificate API' : certificate.pdfPath}'),
          ],
        ),
      ),
    );
  }
}

class _SavedCertificatesCard extends StatelessWidget {
  final List<CertificateRecordModel> certificates;

  const _SavedCertificatesCard({required this.certificates});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved Certificates', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            for (final certificate in certificates.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.workspace_premium),
                title: Text('${certificate.roleName} • ${certificate.totalScore}%'),
                subtitle: Text('${certificate.verificationId} • ${certificate.status}'),
              ),
          ],
        ),
      ),
    );
  }
}
