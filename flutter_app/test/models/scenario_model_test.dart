import 'package:career_chaos_academy/models/mini_game_model.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const role = RoleModel(
    id: 'developer',
    name: 'Developer',
    description: 'Build and debug software under pressure.',
    iconKey: 'code',
  );

  Map<String, dynamic> validScenarioJson({String? story, String? scenario}) {
    return <String, dynamic>{
      'id': 'developer_login_bug',
      'title': 'The Login Button Disaster',
      'difficulty': 'Beginner',
      'theme': 'Debugging and ownership',
      if (story != null) 'story': story,
      if (scenario != null) 'scenario': scenario,
      'task': 'Fix the login issue without creating more chaos.',
      'professionalLearningPoint': 'Debug with evidence before guessing.',
      'choices': <Map<String, dynamic>>[
        <String, dynamic>{
          'text': 'Read logs and reproduce the bug.',
          'outcome': <String, dynamic>{
            'title': 'Clean Fix',
            'description': 'You identify the missing null check and patch safely.',
            'moralLesson': 'Calm debugging beats random changes.',
          },
          'scoreImpact': <String, dynamic>{
            'skill': 4,
            'discipline': 3,
            'ethics': 1,
            'communication': 2,
            'chaos': 0,
          },
        },
        <String, dynamic>{
          'text': 'Restart production repeatedly.',
          'outcome': <String, dynamic>{
            'title': 'Server Disco',
            'description': 'Users see loading spinners doing garba.',
            'moralLesson': 'Do not hide root causes with restarts.',
          },
          'scoreImpact': <String, dynamic>{
            'skill': -1,
            'discipline': -2,
            'ethics': 0,
            'communication': -1,
            'chaos': 5,
          },
        },
      ],
    };
  }

  test('parses scenario with story, choices, outcomes, and score impact', () {
    final scenario = ScenarioModel.fromJson(
      validScenarioJson(story: 'Login fails only on Friday deployments.'),
      role: role,
    );

    expect(scenario.id, 'developer_login_bug');
    expect(scenario.role.name, 'Developer');
    expect(scenario.story, contains('Friday'));
    expect(scenario.choices, hasLength(2));
    expect(scenario.choices.first.outcome.moralLesson, contains('debugging'));
    expect(scenario.choices.first.scoreImpact.skill, 4);
  });

  test('supports generated AI content that uses scenario instead of story', () {
    final scenario = ScenarioModel.fromJson(
      validScenarioJson(scenario: 'Generated story text from the AI lab.'),
      role: role,
    );

    expect(scenario.story, 'Generated story text from the AI lab.');
  });

  test('parses optional code_fix mini-game configuration', () {
    final json = validScenarioJson(story: 'A null variable attacks login.');
    json['miniGame'] = <String, dynamic>{
      'id': 'developer_code_fix_null_guard',
      'type': 'code_fix',
      'title': 'Fix the Null Guard',
      'instructions': 'Choose the safest code fix.',
      'prompt': 'String? token; token.length is crashing.',
      'hint': 'Check null before reading length.',
      'options': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'a', 'text': 'if (token != null) use token.length'},
        <String, dynamic>{'id': 'b', 'text': 'force unwrap everything'},
      ],
      'correctOptionIds': <String>['a'],
      'successScoreImpact': <String, dynamic>{
        'skill': 3,
        'discipline': 2,
        'ethics': 1,
        'communication': 0,
        'chaos': 0,
      },
      'failureScoreImpact': <String, dynamic>{
        'skill': -1,
        'discipline': -1,
        'ethics': 0,
        'communication': 0,
        'chaos': 4,
      },
      'successMessage': 'Bug fixed. Production stops crying.',
      'failureMessage': 'Null pointer returns wearing sunglasses.',
    };

    final scenario = ScenarioModel.fromJson(json, role: role);

    expect(scenario.miniGame, isNotNull);
    expect(scenario.miniGame!.type, MiniGameType.codeFix);
    expect(scenario.miniGame!.correctOptionIds, contains('a'));
  });

  test('throws a friendly format error when mandatory narrative is missing', () {
    final json = validScenarioJson(story: 'Temporary story')..remove('story');

    expect(
      () => ScenarioModel.fromJson(json, role: role),
      throwsA(isA<FormatException>()),
    );
  });
}
