import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/organization_model.dart';
import 'api_client.dart';

class CorporateEditionServiceException implements Exception {
  final String message;
  const CorporateEditionServiceException(this.message);

  @override
  String toString() => message;
}

class CorporateEditionService {
  CorporateEditionService._();

  static final CorporateEditionService instance = CorporateEditionService._();
  static const String _localStateKey = 'career_chaos_corporate_edition_v1';

  Future<List<OrganizationModel>> loadOrganizations() async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/organizations');
        final items = json['organizations'];
        if (items is List) {
          return items.whereType<Map<String, dynamic>>().map(OrganizationModel.fromJson).toList(growable: false);
        }
      } on Object {
        // Fallback to local demo organization.
      }
    }
    final state = await _readLocalState();
    return state.organizations;
  }

  Future<OrganizationModel> createOrganization({
    required String name,
    String type = 'college',
    String industry = 'education',
    String actorUserId = 'demo-admin',
  }) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/organizations', <String, dynamic>{
          'name': name,
          'type': type,
          'industry': industry,
          'actorUserId': actorUserId,
          'actorRole': 'org_admin',
          'customScenarioPackIds': <String>['creator_dev_fire_drill_v1'],
        });
        final raw = json['organization'] is Map<String, dynamic> ? json['organization'] as Map<String, dynamic> : json;
        return OrganizationModel.fromJson(raw);
      } on Object {
        // Fallback to local state.
      }
    }
    final state = await _readLocalState();
    final now = DateTime.now().toIso8601String();
    final organization = OrganizationModel(
      id: 'org_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: type,
      industry: industry,
      status: 'active',
      adminUserIds: <String>[actorUserId],
      trainerUserIds: const <String>['demo-trainer'],
      traineeUserIds: const <String>['demo-trainee'],
      customScenarioPackIds: const <String>['creator_dev_fire_drill_v1'],
      createdAt: now,
      updatedAt: now,
    );
    await _writeLocalState(state.copyWith(organizations: <OrganizationModel>[organization, ...state.organizations]));
    return organization;
  }

  Future<BatchModel> createBatch({
    required String organizationId,
    required String title,
    String roleFocus = 'developer',
    List<String> traineeUserIds = const <String>['demo-trainee'],
    String trainerUserId = 'demo-trainer',
  }) async {
    final dueDate = DateTime.now().add(const Duration(days: 14)).toIso8601String();
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/organizations/${Uri.encodeComponent(organizationId)}/batches', <String, dynamic>{
          'title': title,
          'roleFocus': roleFocus,
          'trainerUserIds': <String>[trainerUserId],
          'traineeUserIds': traineeUserIds,
          'dueDate': dueDate,
          'actorUserId': trainerUserId,
          'actorRole': 'trainer',
        });
        final raw = json['batch'];
        if (raw is Map<String, dynamic>) return BatchModel.fromJson(raw);
      } on Object {
        // Fallback to local state.
      }
    }
    final state = await _readLocalState();
    final now = DateTime.now().toIso8601String();
    final batch = BatchModel(
      id: 'batch_${DateTime.now().microsecondsSinceEpoch}',
      organizationId: organizationId,
      title: title,
      roleFocus: roleFocus,
      status: 'active',
      trainerUserIds: <String>[trainerUserId],
      traineeUserIds: traineeUserIds,
      startsAt: now,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );
    await _writeLocalState(state.copyWith(batches: <BatchModel>[batch, ...state.batches]));
    return batch;
  }

  Future<TrainingAssignmentModel> assignScenarioPack({
    required String organizationId,
    required String batchId,
    required String title,
    String roleId = 'developer',
    String scenarioPackId = 'creator_dev_fire_drill_v1',
    String assignedByUserId = 'demo-trainer',
  }) async {
    final dueDate = DateTime.now().add(const Duration(days: 10)).toIso8601String();
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/organizations/${Uri.encodeComponent(organizationId)}/assignments', <String, dynamic>{
          'batchId': batchId,
          'title': title,
          'roleId': roleId,
          'scenarioPackId': scenarioPackId,
          'requiredChapterIds': <String>[],
          'dueDate': dueDate,
          'assignedByUserId': assignedByUserId,
          'actorUserId': assignedByUserId,
          'actorRole': 'trainer',
        });
        final raw = json['assignment'];
        if (raw is Map<String, dynamic>) return TrainingAssignmentModel.fromJson(raw);
      } on Object {
        // Fallback to local state.
      }
    }
    final state = await _readLocalState();
    final now = DateTime.now().toIso8601String();
    final assignment = TrainingAssignmentModel(
      id: 'assignment_${DateTime.now().microsecondsSinceEpoch}',
      organizationId: organizationId,
      batchId: batchId,
      title: title,
      roleId: roleId,
      scenarioPackId: scenarioPackId,
      requiredChapterIds: const <String>[],
      dueDate: dueDate,
      status: 'assigned',
      assignedByUserId: assignedByUserId,
      createdAt: now,
      updatedAt: now,
    );
    await _writeLocalState(state.copyWith(assignments: <TrainingAssignmentModel>[assignment, ...state.assignments]));
    return assignment;
  }

  Future<TraineeProgressModel> saveTraineeProgress({
    required String organizationId,
    required String batchId,
    required String assignmentId,
    String userId = 'demo-trainee',
    String displayName = 'Demo Trainee',
    int progressPercent = 100,
    int score = 88,
  }) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/organizations/${Uri.encodeComponent(organizationId)}/progress', <String, dynamic>{
          'batchId': batchId,
          'assignmentId': assignmentId,
          'userId': userId,
          'displayName': displayName,
          'completedChapterIds': <String>['chapter_demo_complete'],
          'progressPercent': progressPercent,
          'score': score,
          'actorUserId': userId,
          'actorRole': 'trainee',
        });
        final raw = json['progress'];
        if (raw is Map<String, dynamic>) return TraineeProgressModel.fromJson(raw);
      } on Object {
        // Fallback to local state.
      }
    }
    final state = await _readLocalState();
    final now = DateTime.now().toIso8601String();
    final progress = TraineeProgressModel(
      id: 'progress_${DateTime.now().microsecondsSinceEpoch}',
      organizationId: organizationId,
      batchId: batchId,
      assignmentId: assignmentId,
      userId: userId,
      displayName: displayName,
      completedChapterIds: const <String>['chapter_demo_complete'],
      progressPercent: progressPercent,
      score: score,
      status: progressPercent >= 100 ? 'completed' : 'in_progress',
      isOverdue: false,
      completedAt: progressPercent >= 100 ? now : null,
      updatedAt: now,
    );
    await _writeLocalState(state.copyWith(progress: <TraineeProgressModel>[progress, ...state.progress]));
    return progress;
  }

  Future<OrganizationDashboardModel> loadDashboard(String organizationId) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/organizations/${Uri.encodeComponent(organizationId)}/dashboard');
        return OrganizationDashboardModel.fromJson(json);
      } on Object {
        // Fallback to local dashboard.
      }
    }
    final state = await _readLocalState();
    final org = state.organizations.firstWhere(
      (item) => item.id == organizationId,
      orElse: () => state.organizations.isNotEmpty ? state.organizations.first : _demoOrganization(),
    );
    final batches = state.batches.where((item) => item.organizationId == org.id).toList(growable: false);
    final assignments = state.assignments.where((item) => item.organizationId == org.id).toList(growable: false);
    final progress = state.progress.where((item) => item.organizationId == org.id).toList(growable: false);
    final averageProgress = progress.isEmpty ? 0 : (progress.fold<int>(0, (sum, item) => sum + item.progressPercent) / progress.length).round();
    final averageScore = progress.isEmpty ? 0 : (progress.fold<int>(0, (sum, item) => sum + item.score) / progress.length).round();
    return OrganizationDashboardModel(
      organizationId: org.id,
      organizationName: org.name,
      batchCount: batches.length,
      traineeCount: org.traineeUserIds.length,
      assignmentCount: assignments.length,
      completedCount: progress.where((item) => item.status == 'completed').length,
      overdueCount: progress.where((item) => item.isOverdue).length,
      averageProgress: averageProgress,
      averageScore: averageScore,
      progress: progress,
      assignments: assignments,
      batches: batches,
    );
  }

  Future<String> exportReport(String organizationId) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/organizations/${Uri.encodeComponent(organizationId)}/reports/export?format=json');
        return const JsonEncoder.withIndent('  ').convert(json);
      } on Object {
        // Fallback to local JSON report.
      }
    }
    final dashboard = await loadDashboard(organizationId);
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'organizationId': dashboard.organizationId,
      'organizationName': dashboard.organizationName,
      'summary': <String, dynamic>{
        'batchCount': dashboard.batchCount,
        'traineeCount': dashboard.traineeCount,
        'assignmentCount': dashboard.assignmentCount,
        'completedCount': dashboard.completedCount,
        'overdueCount': dashboard.overdueCount,
        'averageProgress': dashboard.averageProgress,
        'averageScore': dashboard.averageScore,
      },
      'progress': dashboard.progress.map((item) => item.toJson()).toList(growable: false),
    });
  }

  Future<_CorporateLocalState> _readLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localStateKey);
    if (raw == null || raw.trim().isEmpty) return _CorporateLocalState.demo();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return _CorporateLocalState.fromJson(decoded);
    } on Object {
      return _CorporateLocalState.demo();
    }
    return _CorporateLocalState.demo();
  }

  Future<void> _writeLocalState(_CorporateLocalState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localStateKey, jsonEncode(state.toJson()));
  }
}

class _CorporateLocalState {
  final List<OrganizationModel> organizations;
  final List<BatchModel> batches;
  final List<TrainingAssignmentModel> assignments;
  final List<TraineeProgressModel> progress;

  const _CorporateLocalState({required this.organizations, required this.batches, required this.assignments, required this.progress});

  factory _CorporateLocalState.demo() {
    final org = _demoOrganization();
    return _CorporateLocalState(organizations: <OrganizationModel>[org], batches: const <BatchModel>[], assignments: const <TrainingAssignmentModel>[], progress: const <TraineeProgressModel>[]);
  }

  factory _CorporateLocalState.fromJson(Map<String, dynamic> json) {
    return _CorporateLocalState(
      organizations: _mapList(json['organizations']).map(OrganizationModel.fromJson).toList(growable: false),
      batches: _mapList(json['batches']).map(BatchModel.fromJson).toList(growable: false),
      assignments: _mapList(json['assignments']).map(TrainingAssignmentModel.fromJson).toList(growable: false),
      progress: _mapList(json['progress']).map(TraineeProgressModel.fromJson).toList(growable: false),
    );
  }

  _CorporateLocalState copyWith({
    List<OrganizationModel>? organizations,
    List<BatchModel>? batches,
    List<TrainingAssignmentModel>? assignments,
    List<TraineeProgressModel>? progress,
  }) {
    return _CorporateLocalState(
      organizations: organizations ?? this.organizations,
      batches: batches ?? this.batches,
      assignments: assignments ?? this.assignments,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'organizations': organizations.map((item) => item.toJson()).toList(growable: false),
        'batches': batches.map((item) => item.toJson()).toList(growable: false),
        'assignments': assignments.map((item) => item.toJson()).toList(growable: false),
        'progress': progress.map((item) => item.toJson()).toList(growable: false),
      };
}

OrganizationModel _demoOrganization() {
  final now = DateTime.now().toIso8601String();
  return OrganizationModel(
    id: 'demo_college',
    name: 'Demo College Training Lab',
    type: 'college',
    industry: 'education',
    status: 'active',
    adminUserIds: const <String>['demo-admin'],
    trainerUserIds: const <String>['demo-trainer'],
    traineeUserIds: const <String>['demo-trainee'],
    customScenarioPackIds: const <String>['creator_dev_fire_drill_v1'],
    createdAt: now,
    updatedAt: now,
  );
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}
