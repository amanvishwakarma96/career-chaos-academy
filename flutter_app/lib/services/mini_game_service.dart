import '../models/mini_game_answer_model.dart';
import '../models/mini_game_model.dart';
import '../models/mini_game_result_model.dart';

class MiniGameService {
  MiniGameService._();

  static final MiniGameService instance = MiniGameService._();

  MiniGameResultModel validate({
    required MiniGameModel miniGame,
    required MiniGameAnswerModel answer,
  }) {
    final isSuccess = _isCorrect(miniGame: miniGame, answer: answer);

    return MiniGameResultModel(
      miniGameId: miniGame.id,
      type: miniGame.type,
      isSuccess: isSuccess,
      scoreImpact:
          isSuccess ? miniGame.successScoreImpact : miniGame.failureScoreImpact,
      message: isSuccess ? miniGame.successMessage : miniGame.failureMessage,
      selectedOptionIds: Set<String>.unmodifiable(answer.selectedOptionIds),
      pairAnswers: Map<String, String>.unmodifiable(answer.pairAnswers),
      orderedItemIds: List<String>.unmodifiable(answer.orderedItemIds),
    );
  }

  bool _isCorrect({
    required MiniGameModel miniGame,
    required MiniGameAnswerModel answer,
  }) {
    switch (miniGame.type) {
      case MiniGameType.codeFix:
        return answer.selectedOptionIds.length == 1 &&
            _sameSet(answer.selectedOptionIds, miniGame.correctOptionIds);
      case MiniGameType.multipleSelect:
      case MiniGameType.dataCleanup:
      case MiniGameType.decisionMatrix:
        return _sameSet(answer.selectedOptionIds, miniGame.correctOptionIds);
      case MiniGameType.matchPairs:
        return _pairsMatch(miniGame, answer.pairAnswers);
      case MiniGameType.arrangeOrder:
        return _sameOrderedList(
          answer.orderedItemIds,
          miniGame.correctOrderIds,
        );
    }
  }

  bool _pairsMatch(MiniGameModel miniGame, Map<String, String> pairAnswers) {
    if (pairAnswers.length != miniGame.pairs.length) {
      return false;
    }

    for (final pair in miniGame.pairs) {
      if (pairAnswers[pair.leftId] != pair.rightId) {
        return false;
      }
    }

    return true;
  }

  bool _sameSet(Set<String> first, Set<String> second) {
    if (first.length != second.length) {
      return false;
    }
    return first.containsAll(second);
  }

  bool _sameOrderedList(List<String> first, List<String> second) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}
