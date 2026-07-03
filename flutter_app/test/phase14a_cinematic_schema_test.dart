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

  Map<String, dynamic> baseChoices() => <String, dynamic>{
        'choices': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': 'Use evidence and communicate clearly.',
            'outcome': <String, dynamic>{
              'title': 'Controlled Fix',
              'description': 'The team understands the risk and moves safely.',
              'moralLesson': 'Drama is optional; evidence is mandatory.',
            },
            'scoreImpact': <String, dynamic>{
              'skill': 2,
              'discipline': 2,
              'ethics': 1,
              'communication': 2,
              'chaos': -1,
            },
          },
          <String, dynamic>{
            'text': 'Guess loudly and deploy immediately.',
            'outcome': <String, dynamic>{
              'title': 'Cinematic Disaster',
              'description': 'The build breaks with background music.',
              'moralLesson': 'Confidence without evidence is just chaos with posture.',
            },
            'scoreImpact': <String, dynamic>{
              'skill': -1,
              'discipline': -2,
              'ethics': 0,
              'communication': -1,
              'chaos': 4,
            },
          },
        ],
      };

  test('old non-cinematic JSON still loads with empty scenes', () {
    final json = <String, dynamic>{
      'id': 'old_story_chapter',
      'title': 'Old Story Chapter',
      'difficulty': 'Beginner',
      'theme': 'Compatibility',
      'story': 'This is the pre-cinematic story field.',
      'task': 'Choose safely.',
      ...baseChoices(),
    };

    final scenario = ScenarioModel.fromJson(json, role: role);

    expect(scenario.story, contains('pre-cinematic'));
    expect(scenario.scenes, isEmpty);
    expect(scenario.hasCinematicScenes, isFalse);
  });

  test('cinematic JSON loads scenes, dialogue, emotion, image and transition fields', () {
    final json = <String, dynamic>{
      'id': 'cinematic_chapter',
      'title': 'The Build Room Goes Silent',
      'difficulty': 'Medium',
      'theme': 'Cinematic decision pressure',
      'task': 'Make the professional call.',
      'scenes': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'opening',
          'title': 'Office Panic',
          'backgroundImage': 'bg_office_morning',
          'characterImage': 'char_developer_worried',
          'soundEffect': 'notification_ping',
          'transitionType': 'fade',
          'dialogues': <Map<String, dynamic>>[
            <String, dynamic>{
              'speaker': 'Narrator',
              'emotion': 'tense',
              'text': 'The login button spins like it has entered a talent show.',
              'characterImage': 'char_developer_worried',
            },
          ],
        },
      ],
      ...baseChoices(),
    };

    final scenario = ScenarioModel.fromJson(json, role: role);

    expect(scenario.hasCinematicScenes, isTrue);
    expect(scenario.story, contains('login button'));
    expect(scenario.scenes.single.backgroundImage, 'bg_office_morning');
    expect(scenario.scenes.single.transitionType, 'fade');
    expect(scenario.scenes.single.dialogues.single.speaker, 'Narrator');
    expect(scenario.scenes.single.dialogues.single.emotion, 'tense');
    expect(scenario.scenes.single.dialogues.single.characterImage, 'char_developer_worried');
  });
}
