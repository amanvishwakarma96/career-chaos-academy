import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/mini_game_model.dart';

void main() {
  test('mini-game JSON can carry failure consequences', () {
    final miniGame = MiniGameModel.fromJson(<String, dynamic>{
      'id': 'developer_patch',
      'type': 'code_fix',
      'title': 'Patch Review',
      'instructions': 'Pick the safe fix.',
      'prompt': 'Loading never stops.',
      'hint': 'Update state after async call.',
      'options': <Map<String, dynamic>>[
        <String, dynamic>{'id': 'safe', 'text': 'Set loading false'},
        <String, dynamic>{'id': 'bad', 'text': 'Hide spinner'},
      ],
      'correctOptionIds': <String>['safe'],
      'successScoreImpact': <String, dynamic>{'skill': 2},
      'failureScoreImpact': <String, dynamic>{'chaos': 3},
      'successMessage': 'Nice fix.',
      'failureMessage': 'Spinner drama continues.',
      'failureConsequence': <String, dynamic>{
        'setFlags': <String>['mini_game_patch_failed'],
        'unlockCleanupMissionIds': <String>['developer_rollback_cleanup'],
        'reputationImpact': <String, dynamic>{'reliability': -2},
      },
    });

    expect(miniGame.failureConsequence.setFlags, contains('mini_game_patch_failed'));
    expect(miniGame.failureConsequence.unlockCleanupMissionIds, contains('developer_rollback_cleanup'));
    expect(miniGame.failureConsequence.reputationImpact.reliability, -2);
  });
}
