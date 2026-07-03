import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/choice_model.dart';
import 'package:career_chaos_academy/models/outcome_model.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';

void main() {
  const role = RoleModel(
    id: 'developer',
    name: 'Developer',
    description: 'Build software safely.',
    iconKey: 'code',
  );

  test('old scenario JSON still loads with safe Phase 13 defaults', () {
    final scenario = ScenarioModel.fromJson(
      <String, dynamic>{
        'id': 'old_chapter',
        'title': 'Old Chapter',
        'difficulty': 'Beginner',
        'theme': 'Compatibility',
        'story': 'A pre-Phase 13 chapter.',
        'task': 'Choose safely.',
        'choices': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': 'Use process',
            'outcome': <String, dynamic>{
              'title': 'Good',
              'description': 'You used the process.',
              'moralLesson': 'Process protects teams.',
            },
            'scoreImpact': <String, dynamic>{'skill': 1},
          },
          <String, dynamic>{
            'text': 'Panic',
            'outcome': <String, dynamic>{
              'title': 'Chaos',
              'description': 'Chaos happened.',
              'moralLesson': 'Do not panic.',
            },
            'scoreImpact': <String, dynamic>{'chaos': 2},
          },
        ],
      },
      role: role,
    );

    expect(scenario.prerequisites, isEmpty);
    expect(scenario.blockedByFlags, isEmpty);
    expect(scenario.isCleanupMission, isFalse);
    expect(scenario.isFinale, isFalse);
    expect(scenario.requiredScoreMinimums, isNull);
    expect(scenario.choices.first.outcome.setFlags, isEmpty);
    expect(scenario.choices.first.outcome.reputationImpact.total, 0);
  });

  test('new consequence JSON loads with optional Phase 13 fields', () {
    final outcome = OutcomeModel.fromJson(<String, dynamic>{
      'title': 'Rollback Needed',
      'description': 'A production regression appears.',
      'moralLesson': 'Testing prevents emergency rollback.',
      'setFlags': <String>['skipped_testing'],
      'clearFlags': <String>['unknown_root_cause'],
      'unlockCleanupMissionIds': <String>['developer_rollback_cleanup'],
      'reputationImpact': <String, dynamic>{
        'trust': -2,
        'safety': -1,
        'professionalism': -2,
        'reliability': -3,
        'stakeholderConfidence': -2,
      },
      'nextChapterOverrideId': 'developer_regression_chapter',
      'consequenceSummary': 'Your shortcut creates a future regression.',
      'debrief': <String, dynamic>{
        'whatWentWell': 'You acted quickly.',
        'whatWasMissed': 'You skipped test evidence.',
        'realWorldPrinciple': 'Fast fixes need controlled validation.',
      },
    });

    expect(outcome.setFlags, contains('skipped_testing'));
    expect(outcome.clearFlags, contains('unknown_root_cause'));
    expect(outcome.unlockCleanupMissionIds, contains('developer_rollback_cleanup'));
    expect(outcome.reputationImpact.reliability, -3);
    expect(outcome.debrief.hasContent, isTrue);
  });

  test('old progress JSON loads with empty Phase 13 maps', () {
    final snapshot = ProgressSnapshotModel.fromJson(<String, dynamic>{
      'version': 3,
      'progressByRole': <String, dynamic>{},
      'totalXp': 0,
      'badges': <String>[],
    });

    expect(snapshot.activeFlagsByRole, isEmpty);
    expect(snapshot.completedCleanupMissions, isEmpty);
    expect(snapshot.roleReputation, isEmpty);
    expect(snapshot.miniGameAttempts, isEmpty);
    expect(snapshot.roleEndings, isEmpty);
  });
}
