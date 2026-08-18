import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/dialogue_line_model.dart';
import 'package:career_chaos_academy/models/outcome_model.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/models/relationship_score_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:career_chaos_academy/services/story_continuity_service.dart';

void main() {
  const role = RoleModel(
    id: 'developer',
    name: 'Developer',
    description: 'Build safely.',
    iconKey: 'code',
  );

  test('old scenario JSON still loads with empty story flag defaults', () {
    final scenario = ScenarioModel.fromJson(<String, dynamic>{
      'id': 'old_chapter',
      'title': 'Old chapter',
      'difficulty': 'beginner',
      'theme': 'debugging',
      'story': 'Old JSON remains compatible.',
      'task': 'Choose safely.',
      'choices': <Map<String, dynamic>>[
        <String, dynamic>{
          'text': 'Test first',
          'scoreImpact': <String, dynamic>{'skill': 1},
          'outcome': <String, dynamic>{
            'title': 'Good',
            'description': 'Safe.',
            'moralLesson': 'Test.',
          },
        },
      ],
    }, role: role);

    expect(scenario.requiredStoryFlags, isEmpty);
    expect(scenario.blockedStoryFlags, isEmpty);
    expect(scenario.adaptiveDialogueInjections, isEmpty);
  });

  test('outcome parses story flags, relationship impact, and delayed messages', () {
    final outcome = OutcomeModel.fromJson(<String, dynamic>{
      'title': 'Trust shaken',
      'description': 'The client noticed.',
      'moralLesson': 'Document first.',
      'setStoryFlags': <String>['client_trust_shaken'],
      'clearStoryFlags': <String>['client_relaxed'],
      'relationshipImpact': <String, dynamic>{
        'mentorTrust': -2,
        'clientTrust': -3,
        'teamTrust': -1,
      },
      'delayedConsequenceMessages': <String>[
        'Senior Dev will ask for evidence next time.',
      ],
    });

    expect(outcome.setStoryFlags, contains('client_trust_shaken'));
    expect(outcome.clearStoryFlags, contains('client_relaxed'));
    expect(outcome.relationshipImpact.clientTrust, -3);
    expect(outcome.delayedConsequenceMessages.single, contains('evidence'));
  });

  test('conditional dialogue checks story flags', () {
    final line = DialogueLineModel.fromJson(<String, dynamic>{
      'speaker': 'Mentor',
      'text': 'Show me the logs.',
      'requiredStoryFlags': <String>['mentor_warned_after_shortcut'],
      'blockedStoryFlags': <String>['mentor_confidence_growing'],
    });

    expect(
      StoryContinuityService.instance.isDialogueVisible(
        line: line,
        storyFlags: const <String>{'mentor_warned_after_shortcut'},
        relationship: RelationshipScoreModel.zero,
      ),
      isTrue,
    );
    expect(
      StoryContinuityService.instance.isDialogueVisible(
        line: line,
        storyFlags: const <String>{
          'mentor_warned_after_shortcut',
          'mentor_confidence_growing',
        },
        relationship: RelationshipScoreModel.zero,
      ),
      isFalse,
    );
  });

  test('relationship impact clamps and ending rules can win', () {
    const current = RelationshipScoreModel(
      mentorTrust: 4,
      clientTrust: 3,
      teamTrust: 3,
    );
    const delta = RelationshipScoreModel(
      mentorTrust: 4,
      clientTrust: 4,
      teamTrust: 4,
    );
    final updated = current.add(delta);
    expect(updated.mentorTrust, 5);

    final ending = StoryContinuityService.instance.resolveRoleEnding(
      roleId: 'developer',
      storyFlags: const <String>{'documented_before_fix'},
      relationship: updated,
    );

    expect(ending, 'Production-Safe Developer');
  });

  test('progress snapshot saves Phase 17 continuity fields', () {
    final snapshot = ProgressSnapshotModel.fromJson(<String, dynamic>{
      'storyFlagsByRole': {
        'developer': ['mentor_warned_after_shortcut'],
      },
      'relationshipScoresByRole': {
        'developer': {'mentorTrust': -2, 'clientTrust': -1},
      },
      'delayedConsequencesByRole': {
        'developer': ['Senior Dev will ask for evidence next time.'],
      },
    });

    expect(
      snapshot.storyFlagsByRole['developer'],
      contains('mentor_warned_after_shortcut'),
    );
    expect(snapshot.relationshipScoresByRole['developer']?.mentorTrust, -2);
    expect(
      snapshot.delayedConsequencesByRole['developer']?.single,
      contains('evidence'),
    );
    expect(
      snapshot.toJson()['version'],
      ProgressSnapshotModel.currentVersion,
    );
  });
}
