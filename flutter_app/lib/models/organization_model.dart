class OrganizationModel {
  final String id;
  final String name;
  final String type;
  final String industry;
  final String status;
  final List<String> adminUserIds;
  final List<String> trainerUserIds;
  final List<String> traineeUserIds;
  final List<String> customScenarioPackIds;
  final List<BatchModel> batches;
  final List<TrainingAssignmentModel> assignments;
  final String createdAt;
  final String updatedAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.industry,
    required this.status,
    required this.adminUserIds,
    required this.trainerUserIds,
    required this.traineeUserIds,
    required this.customScenarioPackIds,
    this.batches = const <BatchModel>[],
    this.assignments = const <TrainingAssignmentModel>[],
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Training Organization'),
      type: _string(json['type'], fallback: 'college'),
      industry: _string(json['industry'], fallback: 'education'),
      status: _string(json['status'], fallback: 'active'),
      adminUserIds: _stringList(json['adminUserIds']),
      trainerUserIds: _stringList(json['trainerUserIds']),
      traineeUserIds: _stringList(json['traineeUserIds']),
      customScenarioPackIds: _stringList(json['customScenarioPackIds']),
      batches: _mapList(json['batches']).map(BatchModel.fromJson).toList(growable: false),
      assignments: _mapList(json['assignments']).map(TrainingAssignmentModel.fromJson).toList(growable: false),
      createdAt: _string(json['createdAt'], fallback: DateTime.now().toIso8601String()),
      updatedAt: _string(json['updatedAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type,
        'industry': industry,
        'status': status,
        'adminUserIds': adminUserIds,
        'trainerUserIds': trainerUserIds,
        'traineeUserIds': traineeUserIds,
        'customScenarioPackIds': customScenarioPackIds,
        'batches': batches.map((item) => item.toJson()).toList(growable: false),
        'assignments': assignments.map((item) => item.toJson()).toList(growable: false),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class BatchModel {
  final String id;
  final String organizationId;
  final String title;
  final String roleFocus;
  final String status;
  final List<String> trainerUserIds;
  final List<String> traineeUserIds;
  final String startsAt;
  final String dueDate;
  final String createdAt;
  final String updatedAt;

  const BatchModel({
    required this.id,
    required this.organizationId,
    required this.title,
    required this.roleFocus,
    required this.status,
    required this.trainerUserIds,
    required this.traineeUserIds,
    required this.startsAt,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: _string(json['id']),
      organizationId: _string(json['organizationId']),
      title: _string(json['title'], fallback: 'Training Batch'),
      roleFocus: _string(json['roleFocus'], fallback: 'all_roles'),
      status: _string(json['status'], fallback: 'active'),
      trainerUserIds: _stringList(json['trainerUserIds']),
      traineeUserIds: _stringList(json['traineeUserIds']),
      startsAt: _string(json['startsAt'], fallback: DateTime.now().toIso8601String()),
      dueDate: _string(json['dueDate'], fallback: DateTime.now().add(const Duration(days: 14)).toIso8601String()),
      createdAt: _string(json['createdAt'], fallback: DateTime.now().toIso8601String()),
      updatedAt: _string(json['updatedAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'organizationId': organizationId,
        'title': title,
        'roleFocus': roleFocus,
        'status': status,
        'trainerUserIds': trainerUserIds,
        'traineeUserIds': traineeUserIds,
        'startsAt': startsAt,
        'dueDate': dueDate,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class TrainingAssignmentModel {
  final String id;
  final String organizationId;
  final String batchId;
  final String title;
  final String roleId;
  final String scenarioPackId;
  final List<String> requiredChapterIds;
  final String dueDate;
  final String status;
  final String assignedByUserId;
  final String createdAt;
  final String updatedAt;

  const TrainingAssignmentModel({
    required this.id,
    required this.organizationId,
    required this.batchId,
    required this.title,
    required this.roleId,
    required this.scenarioPackId,
    required this.requiredChapterIds,
    required this.dueDate,
    required this.status,
    required this.assignedByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainingAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TrainingAssignmentModel(
      id: _string(json['id']),
      organizationId: _string(json['organizationId']),
      batchId: _string(json['batchId']),
      title: _string(json['title'], fallback: 'Assigned Career Chaos Training'),
      roleId: _string(json['roleId'], fallback: 'developer'),
      scenarioPackId: _string(json['scenarioPackId']),
      requiredChapterIds: _stringList(json['requiredChapterIds']),
      dueDate: _string(json['dueDate'], fallback: DateTime.now().add(const Duration(days: 7)).toIso8601String()),
      status: _string(json['status'], fallback: 'assigned'),
      assignedByUserId: _string(json['assignedByUserId'], fallback: 'trainer'),
      createdAt: _string(json['createdAt'], fallback: DateTime.now().toIso8601String()),
      updatedAt: _string(json['updatedAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'organizationId': organizationId,
        'batchId': batchId,
        'title': title,
        'roleId': roleId,
        'scenarioPackId': scenarioPackId,
        'requiredChapterIds': requiredChapterIds,
        'dueDate': dueDate,
        'status': status,
        'assignedByUserId': assignedByUserId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class TraineeProgressModel {
  final String id;
  final String organizationId;
  final String batchId;
  final String assignmentId;
  final String userId;
  final String displayName;
  final List<String> completedChapterIds;
  final int progressPercent;
  final int score;
  final String status;
  final bool isOverdue;
  final String? completedAt;
  final String updatedAt;

  const TraineeProgressModel({
    required this.id,
    required this.organizationId,
    required this.batchId,
    required this.assignmentId,
    required this.userId,
    required this.displayName,
    required this.completedChapterIds,
    required this.progressPercent,
    required this.score,
    required this.status,
    required this.isOverdue,
    required this.completedAt,
    required this.updatedAt,
  });

  factory TraineeProgressModel.fromJson(Map<String, dynamic> json) {
    return TraineeProgressModel(
      id: _string(json['id']),
      organizationId: _string(json['organizationId']),
      batchId: _string(json['batchId']),
      assignmentId: _string(json['assignmentId']),
      userId: _string(json['userId']),
      displayName: _string(json['displayName'], fallback: 'Trainee'),
      completedChapterIds: _stringList(json['completedChapterIds']),
      progressPercent: _int(json['progressPercent']),
      score: _int(json['score']),
      status: _string(json['status'], fallback: 'not_started'),
      isOverdue: json['isOverdue'] == true,
      completedAt: json['completedAt'] is String ? json['completedAt'] as String : null,
      updatedAt: _string(json['updatedAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'organizationId': organizationId,
        'batchId': batchId,
        'assignmentId': assignmentId,
        'userId': userId,
        'displayName': displayName,
        'completedChapterIds': completedChapterIds,
        'progressPercent': progressPercent,
        'score': score,
        'status': status,
        'isOverdue': isOverdue,
        'completedAt': completedAt,
        'updatedAt': updatedAt,
      };
}

class OrganizationDashboardModel {
  final String organizationId;
  final String organizationName;
  final int batchCount;
  final int traineeCount;
  final int assignmentCount;
  final int completedCount;
  final int overdueCount;
  final int averageProgress;
  final int averageScore;
  final List<TraineeProgressModel> progress;
  final List<TrainingAssignmentModel> assignments;
  final List<BatchModel> batches;

  const OrganizationDashboardModel({
    required this.organizationId,
    required this.organizationName,
    required this.batchCount,
    required this.traineeCount,
    required this.assignmentCount,
    required this.completedCount,
    required this.overdueCount,
    required this.averageProgress,
    required this.averageScore,
    required this.progress,
    required this.assignments,
    required this.batches,
  });

  factory OrganizationDashboardModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map<String, dynamic> ? json['summary'] as Map<String, dynamic> : const <String, dynamic>{};
    return OrganizationDashboardModel(
      organizationId: _string(json['organizationId']),
      organizationName: _string(json['organizationName'], fallback: 'Organization'),
      batchCount: _int(summary['batchCount']),
      traineeCount: _int(summary['traineeCount']),
      assignmentCount: _int(summary['assignmentCount']),
      completedCount: _int(summary['completedCount']),
      overdueCount: _int(summary['overdueCount']),
      averageProgress: _int(summary['averageProgress']),
      averageScore: _int(summary['averageScore']),
      progress: _mapList(json['progress']).map(TraineeProgressModel.fromJson).toList(growable: false),
      assignments: _mapList(json['assignments']).map(TrainingAssignmentModel.fromJson).toList(growable: false),
      batches: _mapList(json['batches']).map(BatchModel.fromJson).toList(growable: false),
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return fallback;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().where((item) => item.trim().isNotEmpty).map((item) => item.trim()).toList(growable: false);
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}
