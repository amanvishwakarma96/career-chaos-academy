import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/games/blueprint_safety_puzzle_game.dart';
import 'package:career_chaos_academy/games/bug_hunt_room_game.dart';
import 'package:career_chaos_academy/games/data_cleanup_race_game.dart';
import 'package:career_chaos_academy/models/flame_mini_game_model.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/models/score_model.dart';

void main() {
  group('Phase 20 Flame hybrid mini-games', () {
    test('three required Flame mini-games have playable definitions', () {
      final definitions = [
        BugHuntRoomGame.definition,
        DataCleanupRaceGame.definition,
        BlueprintSafetyPuzzleGame.definition,
      ];

      expect(definitions.map((item) => item.kind).toSet(), containsAll([
        FlameMiniGameKind.bugHuntRoom,
        FlameMiniGameKind.dataCleanupRace,
        FlameMiniGameKind.blueprintSafetyPuzzle,
      ]));
      expect(definitions.every((item) => item.targets.length >= 5), isTrue);
      expect(definitions.every((item) => item.successXp > item.failureXp), isTrue);
      expect(definitions.every((item) => item.timeLimitSeconds > 0), isTrue);
    });

    test('Flame mini-game result serializes into progress safely', () {
      final result = FlameMiniGameResultModel(
        gameId: 'flame_bug_hunt_room',
        kind: FlameMiniGameKind.bugHuntRoom,
        title: 'Bug Hunt Room',
        completedAt: DateTime.utc(2026, 6, 16),
        isSuccess: true,
        correctCount: 3,
        wrongCount: 0,
        elapsedSeconds: 20,
        xpEarned: 120,
        scoreImpact: const ScoreModel(skill: 5, discipline: 3, ethics: 1),
        selectedTargetIds: const {'null_token', 'ios_keyboard_overlap'},
        message: 'Cleared',
      );

      final snapshot = ProgressSnapshotModel(
        totalXp: 120,
        flameMiniGameHistory: [result],
        flameMiniGameXp: 120,
        flameMiniGameScore: result.scoreImpact,
      );
      final parsed = ProgressSnapshotModel.fromJson(snapshot.toJson());

      expect(parsed.flameMiniGameXp, 120);
      expect(parsed.flameMiniGameHistory.single.gameId, 'flame_bug_hunt_room');
      expect(parsed.flameMiniGameScore.skill, 5);
    });

    test('old progress without Flame fields remains compatible', () {
      final parsed = ProgressSnapshotModel.fromJson({
        'version': 6,
        'progressByRole': <String, dynamic>{},
        'totalXp': 0,
      });

      expect(parsed.flameMiniGameHistory, isEmpty);
      expect(parsed.flameMiniGameXp, 0);
      expect(parsed.flameMiniGameScore.total, 0);
    });
  });
}
