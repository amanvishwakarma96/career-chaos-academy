import 'outcome_model.dart';

class ConsequenceUpdateModel {
  final Set<String> activeFlags;
  final Set<String> flagsSet;
  final Set<String> flagsCleared;
  final Set<String> unlockedCleanupMissionIds;

  const ConsequenceUpdateModel({
    required this.activeFlags,
    this.flagsSet = const <String>{},
    this.flagsCleared = const <String>{},
    this.unlockedCleanupMissionIds = const <String>{},
  });

  factory ConsequenceUpdateModel.fromOutcome({
    required Set<String> currentFlags,
    required OutcomeModel outcome,
  }) {
    final updatedFlags = Set<String>.from(currentFlags);
    final flagsSet = <String>{};
    final flagsCleared = <String>{};

    for (final flag in outcome.setFlags) {
      if (updatedFlags.add(flag)) {
        flagsSet.add(flag);
      }
    }

    for (final flag in outcome.clearFlags) {
      if (updatedFlags.remove(flag)) {
        flagsCleared.add(flag);
      }
    }

    return ConsequenceUpdateModel(
      activeFlags: Set<String>.unmodifiable(updatedFlags),
      flagsSet: Set<String>.unmodifiable(flagsSet),
      flagsCleared: Set<String>.unmodifiable(flagsCleared),
      unlockedCleanupMissionIds: Set<String>.unmodifiable(
        outcome.unlockCleanupMissionIds,
      ),
    );
  }
}
