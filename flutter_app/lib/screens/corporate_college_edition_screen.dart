import 'package:flutter/material.dart';

import '../models/organization_model.dart';
import '../services/corporate_edition_service.dart';
import '../widgets/empty_state.dart';

class CorporateCollegeEditionScreen extends StatefulWidget {
  const CorporateCollegeEditionScreen({super.key});

  @override
  State<CorporateCollegeEditionScreen> createState() => _CorporateCollegeEditionScreenState();
}

class _CorporateCollegeEditionScreenState extends State<CorporateCollegeEditionScreen> {
  late Future<List<OrganizationModel>> _organizationsFuture;
  OrganizationModel? _selectedOrganization;
  BatchModel? _latestBatch;
  TrainingAssignmentModel? _latestAssignment;
  OrganizationDashboardModel? _dashboard;
  String _reportPreview = '';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _organizationsFuture = CorporateEditionService.instance.loadOrganizations();
  }

  Future<void> _reload() async {
    setState(() {
      _organizationsFuture = CorporateEditionService.instance.loadOrganizations();
    });
  }

  Future<void> _createOrganization() async {
    await _runAction(() async {
      final organization = await CorporateEditionService.instance.createOrganization(
        name: 'Career Chaos Corporate Demo',
        type: 'company',
        industry: 'software_training',
      );
      _selectedOrganization = organization;
      _latestBatch = null;
      _latestAssignment = null;
      _dashboard = await CorporateEditionService.instance.loadDashboard(organization.id);
      await _reload();
    });
  }

  Future<void> _createBatch() async {
    final organization = _selectedOrganization;
    if (organization == null) return;
    await _runAction(() async {
      _latestBatch = await CorporateEditionService.instance.createBatch(
        organizationId: organization.id,
        title: 'Flutter Career Readiness Batch',
        roleFocus: 'developer',
        traineeUserIds: const <String>['trainee-a', 'trainee-b', 'trainee-c'],
      );
      _dashboard = await CorporateEditionService.instance.loadDashboard(organization.id);
    });
  }

  Future<void> _assignScenarioPack() async {
    final organization = _selectedOrganization;
    final batch = _latestBatch;
    if (organization == null || batch == null) return;
    await _runAction(() async {
      _latestAssignment = await CorporateEditionService.instance.assignScenarioPack(
        organizationId: organization.id,
        batchId: batch.id,
        title: 'Developer Fire Drill Scenario Pack',
        roleId: 'developer',
        scenarioPackId: 'creator_dev_fire_drill_v1',
      );
      _dashboard = await CorporateEditionService.instance.loadDashboard(organization.id);
    });
  }

  Future<void> _completeTraining() async {
    final organization = _selectedOrganization;
    final batch = _latestBatch;
    final assignment = _latestAssignment;
    if (organization == null || batch == null || assignment == null) return;
    await _runAction(() async {
      await CorporateEditionService.instance.saveTraineeProgress(
        organizationId: organization.id,
        batchId: batch.id,
        assignmentId: assignment.id,
        userId: 'trainee-a',
        displayName: 'Trainee A',
        progressPercent: 100,
        score: 91,
      );
      _dashboard = await CorporateEditionService.instance.loadDashboard(organization.id);
    });
  }

  Future<void> _loadDashboard(OrganizationModel organization) async {
    await _runAction(() async {
      _selectedOrganization = organization;
      _dashboard = await CorporateEditionService.instance.loadDashboard(organization.id);
      _reportPreview = '';
    });
  }

  Future<void> _exportReport() async {
    final organization = _selectedOrganization;
    if (organization == null) return;
    await _runAction(() async {
      _reportPreview = await CorporateEditionService.instance.exportReport(organization.id);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Corporate & College Edition')),
      body: FutureBuilder<List<OrganizationModel>>(
        future: _organizationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _dashboard == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final organizations = snapshot.data ?? const <OrganizationModel>[];
          if (organizations.isEmpty) {
            return EmptyState(
              icon: Icons.business,
              title: 'No organization yet',
              message: 'Create a college, company, or coaching institute workspace to assign role-based training.',
              actionLabel: 'Create Demo Organization',
              onActionPressed: _createOrganization,
            );
          }
          final selected = _selectedOrganization ?? organizations.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(
                organization: selected,
                isBusy: _isBusy,
                onCreateOrganization: _createOrganization,
                onRefresh: _reload,
              ),
              const SizedBox(height: 12),
              _OrganizationPicker(
                organizations: organizations,
                selectedId: selected.id,
                onChanged: (value) {
                  final matches = organizations.where((item) => item.id == value);
                  if (matches.isNotEmpty) _loadDashboard(matches.first);
                },
              ),
              const SizedBox(height: 12),
              _ActionPanel(
                canCreateBatch: selected.id.isNotEmpty,
                canAssign: _latestBatch != null,
                canComplete: _latestAssignment != null,
                onCreateBatch: _createBatch,
                onAssignScenarioPack: _assignScenarioPack,
                onCompleteTraining: _completeTraining,
                onExportReport: _exportReport,
              ),
              const SizedBox(height: 12),
              _DashboardCard(dashboard: _dashboard),
              if (_latestBatch != null) ...[
                const SizedBox(height: 12),
                _InfoTile(title: 'Latest Batch', subtitle: '${_latestBatch!.title} • Due ${_latestBatch!.dueDate.substring(0, 10)}'),
              ],
              if (_latestAssignment != null) ...[
                const SizedBox(height: 12),
                _InfoTile(title: 'Latest Assignment', subtitle: '${_latestAssignment!.title} • Pack ${_latestAssignment!.scenarioPackId}'),
              ],
              if (_reportPreview.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export Report Preview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        SelectableText(_reportPreview, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final OrganizationModel organization;
  final bool isBusy;
  final VoidCallback onCreateOrganization;
  final VoidCallback onRefresh;

  const _HeaderCard({required this.organization, required this.isBusy, required this.onCreateOrganization, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Training-ready platform', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Run role-based scenario packs for colleges, companies, and coaching institutes with due dates, trainer/admin access, dashboards, and exportable reports.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(onPressed: isBusy ? null : onCreateOrganization, icon: const Icon(Icons.add_business), label: const Text('Create Org')),
                OutlinedButton.icon(onPressed: isBusy ? null : onRefresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
                Chip(label: Text('${organization.type} • ${organization.status}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationPicker extends StatelessWidget {
  final List<OrganizationModel> organizations;
  final String selectedId;
  final ValueChanged<String?> onChanged;

  const _OrganizationPicker({required this.organizations, required this.selectedId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: organizations.any((item) => item.id == selectedId) ? selectedId : organizations.first.id,
      decoration: const InputDecoration(labelText: 'Organization workspace', border: OutlineInputBorder()),
      items: organizations.map((item) => DropdownMenuItem<String>(value: item.id, child: Text(item.name))).toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final bool canCreateBatch;
  final bool canAssign;
  final bool canComplete;
  final VoidCallback onCreateBatch;
  final VoidCallback onAssignScenarioPack;
  final VoidCallback onCompleteTraining;
  final VoidCallback onExportReport;

  const _ActionPanel({
    required this.canCreateBatch,
    required this.canAssign,
    required this.canComplete,
    required this.onCreateBatch,
    required this.onAssignScenarioPack,
    required this.onCompleteTraining,
    required this.onExportReport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(onPressed: canCreateBatch ? onCreateBatch : null, icon: const Icon(Icons.groups), label: const Text('Create Batch')),
            FilledButton.tonalIcon(onPressed: canAssign ? onAssignScenarioPack : null, icon: const Icon(Icons.assignment_add), label: const Text('Assign Scenario Pack')),
            FilledButton.tonalIcon(onPressed: canComplete ? onCompleteTraining : null, icon: const Icon(Icons.task_alt), label: const Text('Complete as Trainee')),
            OutlinedButton.icon(onPressed: onExportReport, icon: const Icon(Icons.file_download), label: const Text('Export Report')),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final OrganizationDashboardModel? dashboard;

  const _DashboardCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final data = dashboard;
    if (data == null) {
      return const _InfoTile(title: 'Dashboard', subtitle: 'Select an organization or create a batch to load progress tracking.');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.organizationName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: 'Batches', value: data.batchCount),
                _MetricChip(label: 'Trainees', value: data.traineeCount),
                _MetricChip(label: 'Assignments', value: data.assignmentCount),
                _MetricChip(label: 'Completed', value: data.completedCount),
                _MetricChip(label: 'Overdue', value: data.overdueCount),
                _MetricChip(label: 'Avg Progress', value: data.averageProgress, suffix: '%'),
                _MetricChip(label: 'Avg Score', value: data.averageScore),
              ],
            ),
            const SizedBox(height: 12),
            ...data.progress.take(5).map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person),
                  title: Text(item.displayName),
                  subtitle: Text('${item.status} • ${item.progressPercent}% • score ${item.score}'),
                  trailing: item.isOverdue ? const Icon(Icons.warning_amber, color: Colors.orange) : const Icon(Icons.check_circle_outline),
                )),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final int value;
  final String suffix;

  const _MetricChip({required this.label, required this.value, this.suffix = ''});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value$suffix'));
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
