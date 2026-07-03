import 'package:career_chaos_academy/core/asset_registry.dart';
import 'package:career_chaos_academy/models/role_model.dart';
import 'package:career_chaos_academy/models/scenario_model.dart';
import 'package:career_chaos_academy/services/asset_preload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const role = RoleModel(
    id: 'developer',
    name: 'Developer',
    description: 'Build and debug software under pressure.',
    iconKey: 'code',
  );

  test('asset registry resolves keys, legacy paths, direct paths, and URLs', () {
    expect(
      AssetRegistry.resolve('bg_office_morning', type: GameAssetType.background),
      'assets/game/backgrounds/office_morning.png',
    );
    expect(
      AssetRegistry.resolve(
        'assets/cinematic/characters/developer_worried.png',
        type: GameAssetType.character,
      ),
      'assets/game/characters/developer_worried.png',
    );
    expect(
      AssetRegistry.resolve('assets/custom/example.png'),
      'assets/custom/example.png',
    );
    expect(
      AssetRegistry.resolve('https://cdn.example.com/scene.webp'),
      'https://cdn.example.com/scene.webp',
    );
    expect(AssetRegistry.resolve('unknown_key'), isNull);
  });

  test('scenario JSON can reference visual asset keys safely', () {
    final scenario = ScenarioModel.fromJson(
      <String, dynamic>{
        'id': 'asset_key_scene',
        'title': 'Asset Key Scene',
        'difficulty': 'Beginner',
        'theme': 'Visual system',
        'task': 'Choose after the scene.',
        'scenes': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'opening',
            'backgroundImage': 'bg_office_morning',
            'characterImage': 'char_developer_worried',
            'transitionType': 'fade',
            'dialogues': <Map<String, dynamic>>[
              <String, dynamic>{
                'speaker': 'Narrator',
                'emotion': 'tense',
                'text': 'The war room loads from asset keys.',
                'characterImage': 'char_senior_serious',
              },
            ],
          },
        ],
        'choices': <Map<String, dynamic>>[
          <String, dynamic>{
            'text': 'Proceed with evidence.',
            'outcome': <String, dynamic>{
              'title': 'Prepared',
              'description': 'The scene continues safely.',
              'moralLesson': 'Assets are part of the experience.',
            },
            'scoreImpact': <String, dynamic>{
              'skill': 1,
              'discipline': 1,
              'ethics': 0,
              'communication': 1,
              'chaos': 0,
            },
          },
          <String, dynamic>{
            'text': 'Ignore all missing assets.',
            'outcome': <String, dynamic>{
              'title': 'Placeholder Time',
              'description': 'The fallback keeps the game alive.',
              'moralLesson': 'Never crash because art is late.',
            },
            'scoreImpact': <String, dynamic>{
              'skill': 0,
              'discipline': -1,
              'ethics': 0,
              'communication': 0,
              'chaos': 1,
            },
          },
        ],
      },
      role: role,
    );

    expect(scenario.hasCinematicScenes, isTrue);
    expect(scenario.scenes.single.backgroundImage, 'bg_office_morning');
    expect(
      AssetPreloadService.collectScenarioAssetReferences(scenario),
      containsAll(<String>[
        'bg_office_morning',
        'char_developer_worried',
        'char_senior_serious',
      ]),
    );
  });
}
