import 'package:career_chaos_academy/games/bug_hunt_room_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 36C Developer Bug Hunt game feel', () {
    test('correct production blockers build a correctness-aware combo', () {
      final game = BugHuntRoomGame();

      game.toggleTarget('null_token');
      expect(game.comboCount.value, 1);

      game.toggleTarget('ios_keyboard_overlap');
      expect(game.comboCount.value, 2);

      game.toggleTarget('payment_double_tap');
      expect(game.comboCount.value, 3);

      game.disposeNotifiers();
    });

    test('wrong target immediately resets the combo', () {
      final game = BugHuntRoomGame();

      game.toggleTarget('null_token');
      game.toggleTarget('ios_keyboard_overlap');
      expect(game.comboCount.value, 2);

      game.toggleTarget('coffee_stain');
      expect(game.comboCount.value, 0);

      game.disposeNotifiers();
    });

    test('deselecting a target does not preserve a combo streak', () {
      final game = BugHuntRoomGame();

      game.toggleTarget('null_token');
      expect(game.comboCount.value, 1);

      game.toggleTarget('null_token');
      expect(game.comboCount.value, 0);
      expect(game.selectedTargetIds.value, isNot(contains('null_token')));

      game.disposeNotifiers();
    });

    test('game-feel changes do not alter success XP or score impact', () {
      final game = BugHuntRoomGame();

      game.toggleTarget('null_token');
      game.toggleTarget('ios_keyboard_overlap');
      game.toggleTarget('payment_double_tap');

      final result = game.finish();

      expect(result.isSuccess, isTrue);
      expect(result.xpEarned, BugHuntRoomGame.gameDefinition.successXp);
      expect(
        result.scoreImpact,
        BugHuntRoomGame.gameDefinition.successScoreImpact,
      );
      expect(result.wrongCount, 0);

      game.disposeNotifiers();
    });
  });
}
