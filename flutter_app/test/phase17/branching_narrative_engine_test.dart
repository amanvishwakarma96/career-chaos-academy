import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/dialogue_scene_model.dart';
import 'package:career_chaos_academy/models/ending_rule_model.dart';
import 'package:career_chaos_academy/models/outcome_model.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/models/relationship_score_model.dart';
import 'package:career_chaos_academy/models/reputation_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/role_progress_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/finale_service.dart';
import 'package:career_chaos_academy/services/relationship_service.dart';
import 'package:career_chaos_academy/services/story_continuity_service.dart';

void main() {
  const role = RoleModel(
    id: 'developer',
    name: 'Developer',
    description: 'Build safely.',
    iconKey: 'code',
  );

  test('old scenario JSON still loads with empty story flag defaults', () {
    final scenario = ScenarioModel.fromJson(
      <String, dynamic>{
        'id': 'old_chapter',
        'title': 'Old Chapter',
        'difficulty': 'Beginner',
        'theme': 'Basics',
        'story': 'A normal old story.',
        'task': 'Choose.',
        'choices': <Map<String, dynamic>>[
          {
            'text': 'Good',
            'outcome': {
              'title': 'Good',
              'description': 'Good outcome.',
              'moralLesson': 'Be professional.',
            },
            'scoreImpact': {'skill': 1, 'discipline': 1, 'ethics': 1, 'communication': 1, 'chaos': 0},
          },
          {
            'text': 'Bad',
            'outcome': {
              'title': 'Bad',
              'description': 'Bad outcome.',
              'moralLesson': 'Avoid shortcuts.',
            },
            'scoreImpact': {'skill': 0, 'discipline': 0, 'ethics': 0, 'communication': 0, 'chaos': 1},
          },
        ],
      },
      role: role,
    );

    expect(scenario.requiredStoryFlags, isEmpty);
    expect(scenario.blockedByStoryFlags, isEmpty);
    expect(scenario.endingRules, isEmpty);
  });

  test('outcome parses story flags, relationship impact, and delayed messages', () {
    final outcome = OutcomeModel.fromJson(<String, dynamic>{
      'title': 'Shortcut remembered',
      'description': 'The mentor remembers the shortcut.',
      'moralLesson': 'Relationships remember risky choices.',
      'setStoryFlags': ['mentor_warned_after_shortcut'],
      'clearStoryFlags': ['mentor_confidence_growing'],
      'relationshipImpact': {'mentorTrust': -2, 'clientTrust': -1, 'teamTrust': 0, 'publicReputation': 0},
      'delayedConsequenceMessages': ['Senior Dev will ask for evidence next time.'],
    });

    expect(outcome.setStoryFlags, contains('mentor_warned_after_shortcut'));
    expect(outcome.clearStoryFlags, contains('mentor_confidence_growing'));
    expect(outcome.relationshipImpact.mentorTrust, -2);
    expect(outcome.delayedConsequenceMessages.single, contains('evidence'));
  });

  test('conditional dialogue checks story flags', () {
    final scene = DialogueSceneModel.fromJson(<String, dynamic>{
      'id': 'branch_scene',
      'dialogues': [
        {'speaker': 'Mentor', 'text': 'Default line.'},
        {
          'speaker': 'Mentor',
          'text': 'I remember the shortcut.',
          'requiredStoryFlags': ['mentor_warned_after_shortcut'],
        },
        {
          'speaker': 'Mentor',
          'text': 'You documented your fix well.',
          'requiredStoryFlags': ['documented_before_fix'],
        },
      ],
    });

    final visible = StoryContinuityService.instance.visibleDialogues(
      scene: scene,
      storyFlags: const <String>{'mentor_warned_after_shortcut'},
    );

    expect(visible.map((line) => line.text), contains('I remember the shortcut.'));
    expect(visible.map((line) => line.text), isNot(contains('You documented your fix well.')));
  });

  test('relationship impact clamps and ending rules can win', () {
    final relationship = RelationshipService.instance.applyImpact(
      current: const RelationshipScoreModel(mentorTrust: 99),
      impact: const RelationshipScoreModel(mentorTrust: 9, clientTrust: 2, teamTrust: 2),
    );
    expect(relationship.mentorTrust, 100);

    final ending = FinaleService.instance.calculateEnding(
      progress: const RoleProgressModel(roleId: 'developer'),
      roleScore: const ScoreModel(skill: 10, discipline: 10, ethics: 10, communication: 10, chaos: 0),
      reputation: const ReputationModel(trust: 3, safety: 3),
      activeFlags: const <String>{},
      completedCleanupMissionIds: const <String>{'developer_rollback_cleanup'},
      storyFlags: const <String>{'documented_before_fix'},
      relationship: const RelationshipScoreModel(mentorTrust: 4, clientTrust: 1, teamTrust: 2),
      endingRules: <EndingRuleModel>[
        EndingRuleModel.fromJson(<String, dynamic>{
          'id': 'production_safe_dev',
          'title': 'Production-Safe Developer',
          'requiredStoryFlags': ['documented_before_fix'],
          'requiredRelationshipMinimums': {'mentorTrust': 2, 'clientTrust': 0, 'teamTrust': 1},
          'priority': 100,
        }),
      ],
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

    expect(snapshot.storyFlagsByRole['developer'], contains('mentor_warned_after_shortcut'));
    expect(snapshot.relationshipScoresByRole['developer']?.mentorTrust, -2);
    expect(snapshot.delayedConsequencesByRole['developer']?.single, contains('evidence'));
    expect(snapshot.toJson()['version'], 5);
  });
}
