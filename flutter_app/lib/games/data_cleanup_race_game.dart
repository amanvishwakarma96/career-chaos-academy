import '../models/flame_mini_game_model.dart';
import '../models/score_model.dart';
import 'base_mini_game.dart';

class DataCleanupRaceGame extends BaseMiniGame {
  DataCleanupRaceGame() : super(definition: definition);

  static const FlameMiniGameDefinitionModel definition = FlameMiniGameDefinitionModel(
    id: 'flame_data_cleanup_race',
    kind: FlameMiniGameKind.dataCleanupRace,
    title: 'Data Cleanup Race',
    subtitle: 'Clean the spreadsheet before the audit goblin opens row 404.',
    instructions: 'Select records that must be fixed before processing. Avoid touching valid rows just because they look boring.',
    timeLimitSeconds: 50,
    successThreshold: 3,
    successScoreImpact: ScoreModel(skill: 4, discipline: 5, ethics: 3, communication: 1, chaos: -2),
    failureScoreImpact: ScoreModel(skill: 1, discipline: -2, ethics: -1, communication: 0, chaos: 4),
    successXp: 115,
    failureXp: 30,
    successMessage: 'Cleanup complete. The audit goblin sadly closes Excel and goes home.',
    failureMessage: 'Duplicate rows survived and formed a tiny spreadsheet union. Good lesson, messy file.',
    targets: <FlameMiniGameTargetModel>[
      FlameMiniGameTargetModel(id: 'duplicate_customer', label: 'Duplicate customer record', hint: 'Duplicates create billing and reporting errors.', isCorrect: true, feedback: 'Correct: duplicates must be merged or flagged.'),
      FlameMiniGameTargetModel(id: 'missing_consent', label: 'Missing consent flag', hint: 'Privacy fields are not optional decoration.', isCorrect: true, feedback: 'Correct: privacy-safe processing matters.'),
      FlameMiniGameTargetModel(id: 'invalid_email', label: 'Invalid email format', hint: 'Bad contact data causes workflow failure.', isCorrect: true, feedback: 'Correct: contact validation prevents bounce chaos.'),
      FlameMiniGameTargetModel(id: 'long_name', label: 'Customer has a long name', hint: 'Long is not invalid.', isCorrect: false, feedback: 'Do not punish people for having cinematic names.'),
      FlameMiniGameTargetModel(id: 'green_cell', label: 'Cell is suspiciously green', hint: 'Formatting alone is not a data error.', isCorrect: false, feedback: 'The green cell was innocent. It just likes nature.'),
    ],
  );
}
