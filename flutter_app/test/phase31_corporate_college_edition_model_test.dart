import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/organization_model.dart';

void main() {
  test('Phase 31 organization, batch, assignment, and progress models parse JSON', () {
    final organization = OrganizationModel.fromJson(<String, dynamic>{
      'id': 'org_college_demo',
      'name': 'College Demo',
      'type': 'college',
      'industry': 'education',
      'status': 'active',
      'adminUserIds': <String>['admin-1'],
      'trainerUserIds': <String>['trainer-1'],
      'traineeUserIds': <String>['trainee-1'],
      'customScenarioPackIds': <String>['creator_dev_fire_drill_v1'],
      'createdAt': '2026-06-17T00:00:00.000Z',
      'updatedAt': '2026-06-17T00:00:00.000Z',
    });

    expect(organization.id, 'org_college_demo');
    expect(organization.customScenarioPackIds, contains('creator_dev_fire_drill_v1'));

    final batch = BatchModel.fromJson(<String, dynamic>{
      'id': 'batch_1',
      'organizationId': organization.id,
      'title': 'Developer Batch',
      'roleFocus': 'developer',
      'trainerUserIds': <String>['trainer-1'],
      'traineeUserIds': <String>['trainee-1', 'trainee-2'],
      'dueDate': '2026-06-30T00:00:00.000Z',
    });
    expect(batch.traineeUserIds.length, 2);

    final assignment = TrainingAssignmentModel.fromJson(<String, dynamic>{
      'id': 'assignment_1',
      'organizationId': organization.id,
      'batchId': batch.id,
      'title': 'Developer Fire Drill',
      'roleId': 'developer',
      'scenarioPackId': 'creator_dev_fire_drill_v1',
      'requiredChapterIds': <String>['developer_login_button_disaster'],
    });
    expect(assignment.scenarioPackId, 'creator_dev_fire_drill_v1');

    final progress = TraineeProgressModel.fromJson(<String, dynamic>{
      'id': 'progress_1',
      'organizationId': organization.id,
      'batchId': batch.id,
      'assignmentId': assignment.id,
      'userId': 'trainee-1',
      'displayName': 'Trainee One',
      'completedChapterIds': <String>['developer_login_button_disaster'],
      'progressPercent': 100,
      'score': 91,
      'status': 'completed',
      'isOverdue': false,
    });
    expect(progress.status, 'completed');
    expect(progress.score, 91);

    final dashboard = OrganizationDashboardModel.fromJson(<String, dynamic>{
      'organizationId': organization.id,
      'organizationName': organization.name,
      'summary': <String, dynamic>{
        'batchCount': 1,
        'traineeCount': 2,
        'assignmentCount': 1,
        'completedCount': 1,
        'overdueCount': 0,
        'averageProgress': 100,
        'averageScore': 91,
      },
      'progress': <Map<String, dynamic>>[progress.toJson()],
      'assignments': <Map<String, dynamic>>[assignment.toJson()],
      'batches': <Map<String, dynamic>>[batch.toJson()],
    });
    expect(dashboard.assignmentCount, 1);
    expect(dashboard.completedCount, 1);
    expect(dashboard.progress.single.userId, 'trainee-1');
  });
}
