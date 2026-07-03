import '../models/flame_mini_game_model.dart';
import 'base_mini_game.dart';
import 'blueprint_safety_puzzle_game.dart';
import 'bug_hunt_room_game.dart';
import 'data_cleanup_race_game.dart';

class FlameMiniGameFactory {
  const FlameMiniGameFactory._();

  static List<FlameMiniGameDefinitionModel> get definitions => const <FlameMiniGameDefinitionModel>[
        BugHuntRoomGame.definition,
        DataCleanupRaceGame.definition,
        BlueprintSafetyPuzzleGame.definition,
      ];

  static BaseMiniGame create(FlameMiniGameKind kind) {
    switch (kind) {
      case FlameMiniGameKind.bugHuntRoom:
        return BugHuntRoomGame();
      case FlameMiniGameKind.dataCleanupRace:
        return DataCleanupRaceGame();
      case FlameMiniGameKind.blueprintSafetyPuzzle:
        return BlueprintSafetyPuzzleGame();
    }
  }

  static FlameMiniGameDefinitionModel definitionFor(FlameMiniGameKind kind) {
    return definitions.firstWhere((definition) => definition.kind == kind);
  }
}
