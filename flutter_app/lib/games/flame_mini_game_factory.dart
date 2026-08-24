import '../models/developer_session_model.dart';
import '../models/flame_mini_game_model.dart';
import '../services/developer_session_director_service.dart';
import '../services/progress_service.dart';
import 'base_mini_game.dart';
import 'blueprint_safety_puzzle_game.dart';
import 'bug_hunt_room_game.dart';
import 'data_cleanup_race_game.dart';
import 'developer_release_pipeline_game.dart';

class FlameMiniGameFactory {
  const FlameMiniGameFactory._();

  static List<FlameMiniGameDefinitionModel> get definitions =>
      const <FlameMiniGameDefinitionModel>[
        BugHuntRoomGame.gameDefinition,
        DataCleanupRaceGame.gameDefinition,
        BlueprintSafetyPuzzleGame.gameDefinition,
      ];

  static BaseMiniGame create(FlameMiniGameKind kind) {
    switch (kind) {
      case FlameMiniGameKind.bugHuntRoom:
        final plan = DeveloperSessionDirectorService.instance.nextPlan(
          history: ProgressService.instance.flameMiniGameHistory.value,
        );
        return createDeveloperPlan(plan);
      case FlameMiniGameKind.dataCleanupRace:
        return DataCleanupRaceGame();
      case FlameMiniGameKind.blueprintSafetyPuzzle:
        return BlueprintSafetyPuzzleGame();
    }
  }

  static BaseMiniGame createDeveloperPlan(DeveloperSessionPlan plan) {
    switch (plan.family) {
      case DeveloperTaskFamily.liveIncident:
        return BugHuntRoomGame(sessionPlan: plan);
      case DeveloperTaskFamily.releasePipeline:
        return DeveloperReleasePipelineGame(sessionPlan: plan);
      case DeveloperTaskFamily.supportEscalation:
      case DeveloperTaskFamily.performanceProfiling:
        throw ArgumentError.value(
          plan.family,
          'plan.family',
          'Developer task family is not playable yet.',
        );
    }
  }

  static FlameMiniGameDefinitionModel definitionFor(FlameMiniGameKind kind) {
    return definitions.firstWhere((definition) => definition.kind == kind);
  }
}
