import 'package:career_chaos_academy/games/bug_hunt_room_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Developer Flame reward contract after Phase 36E overhaul', () {
    test('live incident keeps the established success XP and score impact', () {
      final game = BugHuntRoomGame();
      game.selectedTargetIds.value = Set<String>.unmodifiable(
        game.definition.targets.map((target) => target.id),
      );

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

    test('incomplete incident keeps the established failure reward contract', () {
      final game = BugHuntRoomGame();

      final result = game.finish();

      expect(result.isSuccess, isFalse);
      expect(result.xpEarned, BugHuntRoomGame.gameDefinition.failureXp);
      expect(
        result.scoreImpact,
        BugHuntRoomGame.gameDefinition.failureScoreImpact,
      );

      game.disposeNotifiers();
    });

    test('workflow definition has no decoy/wrong-answer cards', () {
      final game = BugHuntRoomGame();

      expect(game.definition.targets, hasLength(6));
      expect(game.definition.targets.every((target) => target.isCorrect), isTrue);
      expect(
        game.definition.targets.map((target) => target.id),
        containsAll(<String>{
          'inspect_logs',
          'reproduce_bug',
          'patch_state',
          'run_tests',
          'open_pr',
          'deploy_fix',
        }),
      );

      game.disposeNotifiers();
    });
  });
}
