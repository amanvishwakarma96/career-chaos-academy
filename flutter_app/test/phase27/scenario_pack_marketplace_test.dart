import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/scenario_pack_model.dart';

void main() {
  test('scenario pack parses metadata and chapters', () {
    final pack = ScenarioPackModel.fromJson(jsonDecode('''
    {
      "id":"creator_dev_fire_drill_v1",
      "title":"Creator Pack",
      "roleId":"developer",
      "roleName":"Developer",
      "difficulty":"Intermediate",
      "creator":{"id":"creator","name":"Creator","verified":true},
      "version":"1.0.0",
      "priceType":"free",
      "safetyStatus":"approved",
      "reviewStatus":"approved",
      "isPublished":true,
      "isFeatured":true,
      "isDownloadable":true,
      "supportsOfflineCache":true,
      "safetyReview":{"status":"approved"},
      "compatibility":{"minAppVersion":"1.0.0","requiredFeatureFlags":[]},
      "chapters":[{"id":"c1","title":"Chapter","difficulty":"Beginner","theme":"T","story":"S","task":"T","choices":[{"text":"A","outcome":{"title":"O","description":"D","moralLesson":"M"},"scoreImpact":{"skill":1}},{"text":"B","outcome":{"title":"O","description":"D","moralLesson":"M"},"scoreImpact":{"skill":0}}]}]
    }
    ''') as Map<String, dynamic>);

    expect(pack.id, 'creator_dev_fire_drill_v1');
    expect(pack.isPublished, isTrue);
    expect(pack.isApproved, isTrue);
    expect(pack.chapterCount, 1);
    expect(pack.isCompatibleWithApp(appVersion: '1.0.0'), isTrue);
  });

  test('scenario pack converts into role scenario', () {
    final pack = ScenarioPackModel.fromJson({
      'id': 'creator_pack',
      'title': 'Pack',
      'roleId': 'developer',
      'roleName': 'Developer',
      'safetyStatus': 'approved',
      'safetyReview': {'status': 'approved'},
      'isPublished': true,
      'chapters': [
        {
          'id': 'pack_chapter',
          'title': 'Pack Chapter',
          'difficulty': 'Beginner',
          'theme': 'Creator workflow',
          'story': 'Story',
          'task': 'Task',
          'choices': [
            {'text': 'A', 'outcome': {'title': 'A', 'description': 'A', 'moralLesson': 'A'}, 'scoreImpact': {'skill': 1}},
            {'text': 'B', 'outcome': {'title': 'B', 'description': 'B', 'moralLesson': 'B'}, 'scoreImpact': {'skill': 0}},
          ],
        }
      ],
    });

    final roleScenario = pack.toRoleScenario();
    expect(roleScenario.role.id, 'developer');
    expect(roleScenario.chapters.single.contentPackId, 'creator_pack');
  });

  test('unapproved pack cannot be published safely', () {
    final pack = ScenarioPackModel.fromJson({
      'id': 'unsafe_draft',
      'title': 'Draft',
      'roleId': 'doctor',
      'roleName': 'Doctor',
      'safetyStatus': 'pending',
      'isPublished': false,
      'chapters': [],
    });

    expect(pack.isApproved, isFalse);
    expect(pack.canPublish, isFalse);
  });
}
