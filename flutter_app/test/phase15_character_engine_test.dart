import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/core/character_registry.dart';
import 'package:career_chaos_academy/models/dialogue_line_model.dart';
import 'package:career_chaos_academy/models/dialogue_scene_model.dart';

void main() {
  group('Phase 15 character emotion engine', () {
    final registry = CharacterRegistry.fromJson({
      'characters': [
        {
          'id': 'mentor_dev',
          'displayName': 'Senior Dev',
          'archetype': 'mentor',
          'defaultEmotion': 'serious',
          'defaultImage': 'char_senior_serious',
          'aliases': ['Tech Lead'],
          'expressions': {
            'serious': 'char_senior_serious',
            'calm': 'char_senior_calm',
          },
        },
        {
          'id': 'deadline_villain',
          'displayName': 'Deadline Demon',
          'archetype': 'pressure_villain',
          'defaultEmotion': 'panic',
          'defaultImage': 'char_manager_panic',
          'aliases': ['PM'],
          'expressions': {
            'panic': 'char_manager_panic',
            'angry': 'char_manager_angry',
          },
        },
      ],
    });

    test('loads character JSON and resolves aliases', () {
      expect(registry.isNotEmpty, isTrue);
      expect(registry.findBySpeaker('Tech Lead')?.id, 'mentor_dev');
      expect(registry.findBySpeaker('PM')?.isVillain, isTrue);
      expect(registry.findById('mentor_dev')?.isMentor, isTrue);
    });

    test('changes expression based on dialogue emotion', () {
      final mentor = registry.findById('mentor_dev');
      expect(mentor?.expressionFor('calm'), 'char_senior_calm');
      expect(mentor?.expressionFor('serious'), 'char_senior_serious');
    });

    test('uses missing expression fallback safely', () {
      final mentor = registry.findById('mentor_dev');
      expect(mentor?.expressionFor('confused'), 'char_senior_serious');
    });

    test('dialogue model supports optional characterId without breaking old JSON', () {
      final oldLine = DialogueLineModel.fromJson({
        'speaker': 'Narrator',
        'emotion': 'tense',
        'text': 'Old scene still works.',
      });
      final newLine = DialogueLineModel.fromJson({
        'speaker': 'Senior Dev',
        'characterId': 'mentor_dev',
        'emotion': 'calm',
        'text': 'Use the rollback plan.',
      });

      expect(oldLine.characterId, isNull);
      expect(newLine.characterId, 'mentor_dev');
    });

    test('scene model supports optional default characterId', () {
      final scene = DialogueSceneModel.fromJson({
        'id': 'mentor_scene',
        'characterId': 'mentor_dev',
        'dialogues': [
          {'speaker': 'Senior Dev', 'text': 'Review first.'},
        ],
      });

      expect(scene.characterId, 'mentor_dev');
      expect(scene.dialogues.first.text, 'Review first.');
    });
  });
}
