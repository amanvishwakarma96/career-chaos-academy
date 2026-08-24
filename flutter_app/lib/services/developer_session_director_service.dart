import 'dart:math' as math;

import '../models/developer_session_model.dart';
import '../models/flame_mini_game_model.dart';

class DeveloperSessionDirectorService {
  const DeveloperSessionDirectorService();

  static const DeveloperSessionDirectorService instance =
      DeveloperSessionDirectorService();

  DeveloperSessionPlan nextPlan({
    required List<FlameMiniGameResultModel> history,
    int? seed,
  }) {
    final recentPlans = _recentPlans(history);
    if (recentPlans.isEmpty) {
      return nextPlanForFamily(
        family: DeveloperTaskFamily.liveIncident,
        history: history,
        seed: seed,
      );
    }

    final random = math.Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final playableFamilies = DeveloperTaskFamily.values
        .where((family) => family.isPlayable)
        .toList(growable: false);
    final lastFamily = recentPlans.first.family;
    final familyCandidates = playableFamilies.length <= 1
        ? playableFamilies
        : playableFamilies.where((family) => family != lastFamily).toList();
    final family = familyCandidates[random.nextInt(familyCandidates.length)];

    return _planForFamily(
      family: family,
      recentPlans: recentPlans,
      random: random,
    );
  }

  DeveloperSessionPlan nextPlanForFamily({
    required DeveloperTaskFamily family,
    required List<FlameMiniGameResultModel> history,
    int? seed,
  }) {
    if (!family.isPlayable) {
      throw ArgumentError.value(
        family,
        'family',
        'Developer task family is not playable yet.',
      );
    }
    final random = math.Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    return _planForFamily(
      family: family,
      recentPlans: _recentPlans(history),
      random: random,
    );
  }

  DeveloperSessionPlan _planForFamily({
    required DeveloperTaskFamily family,
    required List<DeveloperSessionPlan> recentPlans,
    required math.Random random,
  }) {
    final recentModifierIds = recentPlans
        .where((plan) => plan.family == family)
        .take(2)
        .map((plan) => plan.modifier.id)
        .toSet();
    var modifierCandidates = DeveloperIncidentModifier.values
        .where((modifier) => !recentModifierIds.contains(modifier.id))
        .toList(growable: false);
    if (modifierCandidates.isEmpty) {
      modifierCandidates = DeveloperIncidentModifier.values;
    }
    final modifier =
        modifierCandidates[random.nextInt(modifierCandidates.length)];
    return DeveloperSessionPlan(family: family, modifier: modifier);
  }

  List<DeveloperSessionPlan> _recentPlans(
    List<FlameMiniGameResultModel> history,
  ) {
    return history
        .map((result) => planFromGameId(result.gameId))
        .whereType<DeveloperSessionPlan>()
        .take(8)
        .toList(growable: false);
  }

  DeveloperSessionPlan? planFromGameId(String gameId) {
    final parts = gameId.split('|');
    if (parts.length != 3 || parts.first != DeveloperSessionPlan.runIdPrefix) {
      return null;
    }

    DeveloperTaskFamily? family;
    for (final candidate in DeveloperTaskFamily.values) {
      if (candidate.id == parts[1]) {
        family = candidate;
        break;
      }
    }
    if (family == null) {
      return null;
    }

    DeveloperIncidentModifier? modifier;
    for (final candidate in DeveloperIncidentModifier.values) {
      if (candidate.id == parts[2]) {
        modifier = candidate;
        break;
      }
    }
    if (modifier == null) {
      return null;
    }

    return DeveloperSessionPlan(family: family, modifier: modifier);
  }

  List<String> recentModifierIds(
    List<FlameMiniGameResultModel> history, {
    int limit = 6,
  }) {
    return history
        .map((result) => planFromGameId(result.gameId)?.modifier.id)
        .whereType<String>()
        .take(limit)
        .toList(growable: false);
  }
}
