import 'package:career_chaos_academy/models/mini_game_answer_model.dart';
import 'package:career_chaos_academy/models/mini_game_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';
import 'package:career_chaos_academy/services/mini_game_service.dart';
import 'package:flutter_test/flutter_test.dart';

MiniGameModel optionGame(MiniGameType type) => MiniGameModel(
      id: 'game_${type.jsonValue}',
      type: type,
      title: 'Mini Game',
      instructions: 'Pick correct answers.',
      prompt: 'What should be selected?',
      hint: 'Choose stable options.',
      options: const <MiniGameOptionModel>[
        MiniGameOptionModel(id: 'a', text: 'Correct A'),
        MiniGameOptionModel(id: 'b', text: 'Correct B'),
        MiniGameOptionModel(id: 'c', text: 'Wrong C'),
      ],
      correctOptionIds: type == MiniGameType.codeFix ? const <String>{'a'} : const <String>{'a', 'b'},
      successScoreImpact: const ScoreModel(skill: 3, discipline: 2),
      failureScoreImpact: const ScoreModel(skill: -1, chaos: 4),
      successMessage: 'Correct. The office printer salutes you.',
      failureMessage: 'Wrong. The spreadsheet starts laughing in Comic Sans.',
    );

void main() {
  final service = MiniGameService.instance;

  test('Developer code_fix succeeds only for the exact correct option', () {
    final game = optionGame(MiniGameType.codeFix);

    final success = service.validate(
      miniGame: game,
      answer: const MiniGameAnswerModel(selectedOptionIds: <String>{'a'}),
    );
    final failure = service.validate(
      miniGame: game,
      answer: const MiniGameAnswerModel(selectedOptionIds: <String>{'b'}),
    );

    expect(success.isSuccess, isTrue);
    expect(success.scoreImpact.skill, greaterThan(0));
    expect(failure.isSuccess, isFalse);
    expect(failure.message, contains('Comic Sans'));
  });

  test('QA multiple_select validates set equality independent of order', () {
    final game = optionGame(MiniGameType.multipleSelect);

    final result = service.validate(
      miniGame: game,
      answer: const MiniGameAnswerModel(selectedOptionIds: <String>{'b', 'a'}),
    );

    expect(result.isSuccess, isTrue);
  });

  test('Back office data_cleanup fails when one required cleanup item is missed', () {
    final game = optionGame(MiniGameType.dataCleanup);

    final result = service.validate(
      miniGame: game,
      answer: const MiniGameAnswerModel(selectedOptionIds: <String>{'a'}),
    );

    expect(result.isSuccess, isFalse);
    expect(result.scoreImpact.chaos, greaterThan(0));
  });

  test('match_pairs validates each left-to-right mapping', () {
    const game = MiniGameModel(
      id: 'doctor_match_symptoms',
      type: MiniGameType.matchPairs,
      title: 'Match Symptoms',
      instructions: 'Match symptom to safe action.',
      prompt: 'Pair the items.',
      hint: 'Use safe first aid actions only.',
      pairs: <MiniGamePairModel>[
        MiniGamePairModel(leftId: 'fever', leftText: 'Fever', rightId: 'check_temp', rightText: 'Check temperature'),
        MiniGamePairModel(leftId: 'pain', leftText: 'Pain', rightId: 'ask_history', rightText: 'Ask history'),
      ],
      successScoreImpact: ScoreModel(skill: 2),
      failureScoreImpact: ScoreModel(chaos: 3),
      successMessage: 'Safe triage wins.',
      failureMessage: 'The stethoscope requests adult supervision.',
    );

    final result = service.validate(
      miniGame: game,
      answer: const MiniGameAnswerModel(pairAnswers: <String, String>{
        'fever': 'check_temp',
        'pain': 'ask_history',
      }),
    );

    expect(result.isSuccess, isTrue);
  });

  test('arrange_order validates exact sequence', () {
    const game = MiniGameModel(
      id: 'civil_order_steps',
      type: MiniGameType.arrangeOrder,
      title: 'Arrange Site Steps',
      instructions: 'Put tasks in order.',
      prompt: 'Safety comes first.',
      hint: 'Inspect before build.',
      orderItems: <MiniGameOptionModel>[
        MiniGameOptionModel(id: 'inspect', text: 'Inspect'),
        MiniGameOptionModel(id: 'plan', text: 'Plan'),
        MiniGameOptionModel(id: 'build', text: 'Build'),
      ],
      correctOrderIds: <String>['inspect', 'plan', 'build'],
      successScoreImpact: ScoreModel(discipline: 2),
      failureScoreImpact: ScoreModel(chaos: 3),
      successMessage: 'The bridge respects your order.',
      failureMessage: 'The bridge applies for comedy club membership.',
    );

    final result = service.validate(
      miniGame: game,
      answer: const MiniGameAnswerModel(orderedItemIds: <String>['inspect', 'plan', 'build']),
    );

    expect(result.isSuccess, isTrue);
  });
}
