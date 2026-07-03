import '../models/flame_mini_game_model.dart';
import '../models/score_model.dart';
import 'base_mini_game.dart';

class BlueprintSafetyPuzzleGame extends BaseMiniGame {
  BlueprintSafetyPuzzleGame() : super(definition: definition);

  static const FlameMiniGameDefinitionModel definition = FlameMiniGameDefinitionModel(
    id: 'flame_blueprint_safety_puzzle',
    kind: FlameMiniGameKind.blueprintSafetyPuzzle,
    title: 'Blueprint Safety Puzzle',
    subtitle: 'Spot unsafe blueprint issues before the bridge becomes modern art.',
    instructions: 'Select safety-critical design or site issues. Cosmetic complaints can wait until nobody is standing under concrete.',
    timeLimitSeconds: 55,
    successThreshold: 3,
    successScoreImpact: ScoreModel(skill: 5, discipline: 4, ethics: 4, communication: 2, chaos: -3),
    failureScoreImpact: ScoreModel(skill: 1, discipline: -1, ethics: -2, communication: 0, chaos: 5),
    successXp: 130,
    failureXp: 35,
    successMessage: 'Safety puzzle cleared. The site lead salutes with a very official clipboard.',
    failureMessage: 'You approved the decorative fountain but missed the missing railing. The clipboard is judging silently.',
    targets: <FlameMiniGameTargetModel>[
      FlameMiniGameTargetModel(id: 'missing_railing', label: 'Missing safety railing', hint: 'Fall protection is safety-critical.', isCorrect: true, feedback: 'Correct: unsafe edges must be escalated.'),
      FlameMiniGameTargetModel(id: 'load_note_missing', label: 'Load calculation note missing', hint: 'Structural assumptions must be documented.', isCorrect: true, feedback: 'Correct: load assumptions need validation.'),
      FlameMiniGameTargetModel(id: 'blocked_exit', label: 'Emergency exit blocked', hint: 'Life safety overrides aesthetics.', isCorrect: true, feedback: 'Correct: emergency access must stay clear.'),
      FlameMiniGameTargetModel(id: 'ugly_fountain', label: 'Fountain looks emotionally confused', hint: 'Aesthetic issue, not immediate safety.', isCorrect: false, feedback: 'The fountain is dramatic, not dangerous.'),
      FlameMiniGameTargetModel(id: 'paint_shade', label: 'Paint shade is too corporate', hint: 'Branding can wait.', isCorrect: false, feedback: 'Corporate beige is painful, but not a safety stop.'),
    ],
  );
}
