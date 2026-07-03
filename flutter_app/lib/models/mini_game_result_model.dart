import 'mini_game_model.dart';
import 'score_model.dart';

class MiniGameResultModel {
  final String miniGameId;
  final MiniGameType type;
  final bool isSuccess;
  final ScoreModel scoreImpact;
  final String message;
  final Set<String> selectedOptionIds;
  final Map<String, String> pairAnswers;
  final List<String> orderedItemIds;

  const MiniGameResultModel({
    required this.miniGameId,
    required this.type,
    required this.isSuccess,
    required this.scoreImpact,
    required this.message,
    this.selectedOptionIds = const <String>{},
    this.pairAnswers = const <String, String>{},
    this.orderedItemIds = const <String>[],
  });
}
