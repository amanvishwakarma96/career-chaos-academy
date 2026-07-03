import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/adaptive/adaptive_story_model.dart';
import 'package:career_chaos_academy/models/adaptive/user_behavior_summary_model.dart';
import 'package:career_chaos_academy/models/relationship_score_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/adaptive_story_service.dart';

void main() {
  const role = RoleModel(
    id: 'developer',
    name: 'Developer',
    description: 'Build safely.',
    iconKey: 'code',
  );

  test('old static scenario JSON still loads without adaptive fields', () {
    final scenario = ScenarioModel.fromJson(
      <String, dynamic>{
        'id': 'old_chapter',
        'title': 'Old Chapter',
        'difficulty': 'Beginner',
        'theme': 'Compatibility',
        'story': 'Old story still works.',
        'task': 'Choose safely.',
        'choices': [
          {
            'text': 'Document first',
            'scoreImpact': {'skill': 1, 'discipline': 1, 'ethics': 1, 'communication': 1, 'chaos': 0},
            'outcome': {'title': 'Safe', 'description': 'Good.', 'moralLesson': 'Evidence matters.'},
          },
          {
            'text': 'Shortcut',
            'scoreImpact': {'skill': 0, 'discipline': -1, 'ethics': -1, 'communication': 0, 'chaos': 2},
            'outcome': {'title': 'Oops', 'description': 'Bad.', 'moralLesson': 'Shortcuts echo.'},
          },
        ],
      },
      role: role,
    );

    expect(scenario.adaptiveDialogueInjections, isEmpty);
    expect(scenario.adaptiveDifficulty.baseLevel, 'normal');
    expect(scenario.allowsAdaptiveSideMissions, isFalse);
  });

  test('new adaptive scenario JSON parses safely', () {
    final scenario = ScenarioModel.fromJson(
      <String, dynamic>{
        'id': 'adaptive_chapter',
        'title': 'Adaptive Chapter',
        'difficulty': 'Medium',
        'theme': 'Behavior-aware story',
        'story': 'The mentor watches your pattern.',
        'task': 'Choose with evidence.',
        'adaptiveDialogueInjections': [
          {
            'id': 'shortcut_warning',
            'speaker': 'Senior Dev',
            'text': 'Shortcut pattern detected. Slow down and document.',
            'requiredBehaviorPatterns': ['shortcut_prone'],
            'priority': 10,
          }
        ],
        'adaptiveDifficulty': {
          'baseLevel': 'normal',
          'easierLevel': 'guided',
          'harderLevel': 'advanced',
          'increaseWhenPatterns': ['high_performer'],
          'decreaseWhenPatterns': ['shortcut_prone'],
        },
        'allowsAdaptiveSideMissions': true,
        'choices': [
          {
            'text': 'Document first',
            'scoreImpact': {'skill': 1, 'discipline': 1, 'ethics': 1, 'communication': 1, 'chaos': 0},
            'outcome': {'title': 'Safe', 'description': 'Good.', 'moralLesson': 'Evidence matters.'},
          },
          {
            'text': 'Shortcut',
            'scoreImpact': {'skill': 0, 'discipline': -1, 'ethics': -1, 'communication': 0, 'chaos': 2},
            'outcome': {'title': 'Oops', 'description': 'Bad.', 'moralLesson': 'Shortcuts echo.'},
          },
        ],
      },
      role: role,
    );

    expect(scenario.adaptiveDialogueInjections, hasLength(1));
    expect(scenario.adaptiveDifficulty.resolve(const UserBehaviorSummaryModel(behaviorPatterns: ['shortcut_prone'])), 'guided');
    expect(scenario.allowsAdaptiveSideMissions, isTrue);
  });

  test('behavior summary detects weak areas and patterns', () {
    final summary = UserBehaviorSummaryModel.fromScore(
      score: const ScoreModel(skill: 10, discipline: 1, ethics: 0, communication: 0, chaos: 7),
      completedChaptersByRole: {'developer': 2},
      failedMiniGamesByRole: {'developer': 2},
      shortcutChoiceCount: 2,
      ethicalChoiceCount: 0,
    );

    expect(summary.behaviorPatterns, contains('shortcut_prone'));
    expect(summary.behaviorPatterns, contains('repeated_failures'));
    expect(summary.weakSkills, contains('ethics'));
    expect(summary.weakSkills, contains('communication'));
  });

  test('adaptive dialogue injection respects behavior patterns', () {
    final injection = AdaptiveDialogueInjectionModel.fromJson({
      'id': 'mentor_warning',
      'speaker': 'Mentor',
      'text': 'Slow down.',
      'requiredBehaviorPatterns': ['shortcut_prone'],
    });
    final visible = injection.isVisibleFor(const UserBehaviorSummaryModel(behaviorPatterns: ['shortcut_prone']));
    final hidden = injection.isVisibleFor(const UserBehaviorSummaryModel(behaviorPatterns: ['high_performer']));
    expect(visible, isTrue);
    expect(hidden, isFalse);
    expect(injection.toDialogueLine().speaker, 'Mentor');
  });

  test('adaptive side mission draft is draft-only and safety review gated', () {
    final summary = const UserBehaviorSummaryModel(
      weakSkills: ['communication'],
      behaviorPatterns: ['shortcut_prone'],
    );
    const recommendation = AdaptiveStoryRecommendationModel(
      roleId: 'doctor',
      reason: 'Needs safer communication practice.',
      difficulty: 'guided',
      shouldGenerateSideMission: true,
    );
    final draft = AdaptiveStoryService.instance.createSafeSideMissionDraft(
      roleId: 'doctor',
      summary: summary,
      recommendation: recommendation,
    );

    expect(draft.status, 'draft_pending_admin_review');
    expect(draft.generatedJson['mustNotAutoPublish'], isTrue);
    expect(draft.generatedJson['requiresAdminReview'], isTrue);
    expect(AdaptiveStoryService.instance.isDraftSafeForReview(draft), isTrue);
  });

  test('relationship minimums remain compatible with adaptive system imports', () {
    const relationship = RelationshipScoreModel(mentorTrust: 2, clientTrust: 1, teamTrust: 1, publicReputation: 0);
    expect(relationship.mentorTrust, 2);
  });
}
