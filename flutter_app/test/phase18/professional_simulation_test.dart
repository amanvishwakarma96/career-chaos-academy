import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/mini_game_model.dart';
import 'package:career_chaos_academy/models/outcome_model.dart';
import 'package:career_chaos_academy/models/professional/role_skill_map_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:career_chaos_academy/services/professional_simulation_service.dart';

void main() {
  const role = RoleModel(
    id: 'doctor',
    name: 'Doctor',
    description: 'Practice safe triage.',
    iconKey: 'medical_services',
  );

  test('old chapter JSON still loads without professional fields', () {
    final scenario = ScenarioModel.fromJson(
      <String, dynamic>{
        'id': 'old_safe_chapter',
        'title': 'Old Safe Chapter',
        'difficulty': 'Beginner',
        'theme': 'Communication',
        'story': 'Old story format.',
        'task': 'Choose safely.',
        'choices': <Map<String, dynamic>>[
          {
            'text': 'Escalate',
            'outcome': {
              'title': 'Safe',
              'description': 'You escalated safely.',
              'moralLesson': 'Escalate uncertainty.',
            },
            'scoreImpact': {'skill': 1, 'discipline': 1, 'ethics': 1, 'communication': 1, 'chaos': 0},
          },
          {
            'text': 'Guess',
            'outcome': {
              'title': 'Risky',
              'description': 'You guessed.',
              'moralLesson': 'Do not guess.',
            },
            'scoreImpact': {'skill': -1, 'discipline': -1, 'ethics': -1, 'communication': -1, 'chaos': 2},
          },
        ],
      },
      role: role,
    );

    expect(scenario.learningObjective, isEmpty);
    expect(scenario.practicalTakeaway, isEmpty);
    expect(scenario.skillLevel, 'beginner');
  });

  test('new chapter JSON parses skill level, workflow, constraints, and guardrails', () {
    final scenario = ScenarioModel.fromJson(
      <String, dynamic>{
        'id': 'doctor_red_flag_triage',
        'title': 'Red Flag Triage',
        'difficulty': 'Hard',
        'theme': 'Safe escalation',
        'story': 'A patient reports warning signs.',
        'task': 'Choose the safest communication.',
        'learningObjective': 'Recognize red flags and escalate safely.',
        'skillLevel': 'advanced',
        'workflowId': 'initial_triage',
        'skillTags': ['red_flag_triage'],
        'realWorldConstraints': ['time', 'safety', 'documentation'],
        'safetyGuardrails': ['No diagnosis.', 'No prescription.', 'Escalate red flags.'],
        'practicalTakeaway': 'Ask red-flag questions and escalate uncertainty.',
        'safeExplanation': 'This is educational triage only.',
        'mentorFeedback': 'Clinical mentor says: communicate clearly and document.',
        'choices': <Map<String, dynamic>>[
          {
            'text': 'Ask red-flag questions and escalate.',
            'outcome': {
              'title': 'Safe escalation',
              'description': 'You escalated.',
              'moralLesson': 'Safety first.',
              'professionalFeedback': {
                'mentorFeedback': 'Good safe triage.',
                'safeExplanation': 'No diagnosis or dosage was provided.',
                'practicalTakeaway': 'Escalate red flags.',
              },
            },
            'scoreImpact': {'skill': 2, 'discipline': 1, 'ethics': 2, 'communication': 2, 'chaos': 0},
          },
          {
            'text': 'Make a confident diagnosis.',
            'outcome': {
              'title': 'Unsafe certainty',
              'description': 'You overreached.',
              'moralLesson': 'Avoid unsafe certainty.',
            },
            'scoreImpact': {'skill': -2, 'discipline': -1, 'ethics': -3, 'communication': -1, 'chaos': 3},
          },
        ],
      },
      role: role,
    );

    expect(scenario.learningObjective, contains('red flags'));
    expect(scenario.skillLevel, 'advanced');
    expect(scenario.realWorldConstraints, contains('safety'));
    expect(scenario.safetyGuardrails, contains('No prescription.'));
    expect(scenario.choices.first.outcome.mentorFeedback, contains('Good'));
  });

  test('role skill map requires realistic workflows and glossary', () {
    final map = RoleSkillMapModel.fromJson(<String, dynamic>{
      'roleId': 'developer',
      'roleName': 'Developer',
      'mentorName': 'Senior Dev Mentor',
      'skills': [
        {'id': 'debugging', 'name': 'Debugging', 'level': 'beginner', 'description': 'Reproduce and verify bugs.'},
        {'id': 'review', 'name': 'Review', 'level': 'intermediate', 'description': 'Review code and tests.'},
        {'id': 'release', 'name': 'Release Safety', 'level': 'advanced', 'description': 'Plan rollback.'},
      ],
      'workflows': [
        {'id': 'bug_triage', 'title': 'Bug triage workflow', 'level': 'beginner', 'steps': ['Reproduce', 'Check logs', 'Document'], 'constraints': ['time', 'documentation']},
        {'id': 'code_review', 'title': 'Code review workflow', 'level': 'intermediate', 'steps': ['Read diff', 'Check tests', 'Comment'], 'constraints': ['ethics']},
        {'id': 'rollback', 'title': 'Rollback workflow', 'level': 'advanced', 'steps': ['Identify version', 'Rollback', 'Monitor'], 'constraints': ['safety']},
      ],
      'glossary': [
        {'term': 'rollback', 'definition': 'Return to a known safe version.'},
      ],
      'safetyGuardrails': ['Do not hotfix without rollback plan.'],
    });

    expect(map.skills.length, 3);
    expect(map.workflows.length, 3);
    expect(map.hasAdvancedSkill, isTrue);
    expect(map.glossary.single.term, 'rollback');
  });

  test('skill-based mini-game fields are optional and parse when present', () {
    final miniGame = MiniGameModel.fromJson(<String, dynamic>{
      'id': 'qa_severity_sort',
      'type': 'multiple_select',
      'title': 'Severity Sort',
      'instructions': 'Select critical defects.',
      'prompt': 'Which issues must block release?',
      'hint': 'Prioritize user impact and safety.',
      'options': [
        {'id': 'crash', 'text': 'App crashes on payment'},
        {'id': 'typo', 'text': 'One typo in footer'},
      ],
      'correctOptionIds': ['crash'],
      'successScoreImpact': {'skill': 2, 'discipline': 1, 'ethics': 1, 'communication': 1, 'chaos': 0},
      'failureScoreImpact': {'skill': -1, 'discipline': -1, 'ethics': 0, 'communication': 0, 'chaos': 2},
      'successMessage': 'You protected release quality.',
      'failureMessage': 'The typo became famous while payment crashed.',
      'skillLevel': 'intermediate',
      'workflowId': 'release_signoff',
      'skillTags': ['severity_classification'],
    });

    expect(miniGame.skillLevel, 'intermediate');
    expect(miniGame.workflowId, 'release_signoff');
    expect(miniGame.skillTags, contains('severity_classification'));
  });

  test('professional service creates safe fallback explanations and mentor feedback', () {
    final scenario = ScenarioModel.fromJson(
      <String, dynamic>{
        'id': 'doctor_basic',
        'title': 'Doctor Basic',
        'difficulty': 'Beginner',
        'theme': 'Safety',
        'story': 'A simulated case.',
        'task': 'Choose.',
        'safetyDisclaimer': 'No diagnosis or prescription.',
        'choices': <Map<String, dynamic>>[
          {
            'text': 'Escalate',
            'outcome': {'title': 'Good', 'description': 'Good.', 'moralLesson': 'Safety.'},
            'scoreImpact': {'skill': 1, 'discipline': 1, 'ethics': 1, 'communication': 1, 'chaos': 0},
          },
          {
            'text': 'Guess',
            'outcome': {'title': 'Bad', 'description': 'Bad.', 'moralLesson': 'Avoid guessing.'},
            'scoreImpact': {'skill': -1, 'discipline': -1, 'ethics': -1, 'communication': -1, 'chaos': 2},
          },
        ],
      },
      role: role,
    );

    expect(
      ProfessionalSimulationService.instance.safeExplanationForScenario(scenario),
      contains('No diagnosis'),
    );
    expect(
      ProfessionalSimulationService.instance.mentorFeedbackForChoice(
        scenario: scenario,
        outcomeFeedback: '',
      ),
      contains('Mentor note'),
    );
  });
}
