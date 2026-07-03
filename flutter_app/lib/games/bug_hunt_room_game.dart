import '../models/flame_mini_game_model.dart';
import '../models/score_model.dart';
import 'base_mini_game.dart';

class BugHuntRoomGame extends BaseMiniGame {
  BugHuntRoomGame() : super(definition: definition);

  static const FlameMiniGameDefinitionModel definition = FlameMiniGameDefinitionModel(
    id: 'flame_bug_hunt_room',
    kind: FlameMiniGameKind.bugHuntRoom,
    title: 'Bug Hunt Room',
    subtitle: 'Find the risky defects before the release train becomes a clown car.',
    instructions: 'Select only the real production blockers. Coffee stains and scary comments are not bugs, even if they feel personal.',
    timeLimitSeconds: 45,
    successThreshold: 3,
    successScoreImpact: ScoreModel(skill: 5, discipline: 3, communication: 1, ethics: 1, chaos: -2),
    failureScoreImpact: ScoreModel(skill: 1, discipline: -1, communication: 0, ethics: 0, chaos: 3),
    successXp: 120,
    failureXp: 35,
    successMessage: 'Bug hunt cleared. QA nods respectfully. The release train remains on tracks.',
    failureMessage: 'You chased a coffee stain while the login bug escaped wearing sunglasses. Useful chaos, but still chaos.',
    targets: <FlameMiniGameTargetModel>[
      FlameMiniGameTargetModel(id: 'null_token', label: 'Null token after refresh', hint: 'Auth blockers stop users cold.', isCorrect: true, feedback: 'Correct: token refresh bugs block sessions.'),
      FlameMiniGameTargetModel(id: 'ios_keyboard_overlap', label: 'iOS keyboard hides submit', hint: 'Blocks a core flow on one platform.', isCorrect: true, feedback: 'Correct: platform blockers need release attention.'),
      FlameMiniGameTargetModel(id: 'payment_double_tap', label: 'Double-tap creates duplicate payment', hint: 'Money flow issues are high priority.', isCorrect: true, feedback: 'Correct: duplicate payment risk is serious.'),
      FlameMiniGameTargetModel(id: 'coffee_stain', label: 'Coffee stain on Jira screenshot', hint: 'Funny, not a production blocker.', isCorrect: false, feedback: 'Not a blocker. Hydrate the screenshot later.'),
      FlameMiniGameTargetModel(id: 'variable_name_vibe', label: 'Variable name has bad vibes', hint: 'Refactor later unless it causes risk.', isCorrect: false, feedback: 'Code vibes are real, but not release blockers.'),
    ],
  );
}
