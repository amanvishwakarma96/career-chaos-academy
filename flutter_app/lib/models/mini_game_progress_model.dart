import 'mini_game_model.dart';
import 'mini_game_result_model.dart';
import 'score_model.dart';

class MiniGameProgressModel {
  final String miniGameId;
  final String chapterId;
  final MiniGameType type;
  final bool isSuccess;
  final ScoreModel scoreImpact;
  final Set<String> selectedOptionIds;
  final Map<String, String> pairAnswers;
  final List<String> orderedItemIds;

  const MiniGameProgressModel({
    required this.miniGameId,
    required this.chapterId,
    required this.type,
    required this.isSuccess,
    required this.scoreImpact,
    this.selectedOptionIds = const <String>{},
    this.pairAnswers = const <String, String>{},
    this.orderedItemIds = const <String>[],
  });

  factory MiniGameProgressModel.fromResult({
    required String chapterId,
    required MiniGameResultModel result,
  }) {
    return MiniGameProgressModel(
      miniGameId: result.miniGameId,
      chapterId: chapterId,
      type: result.type,
      isSuccess: result.isSuccess,
      scoreImpact: result.scoreImpact,
      selectedOptionIds: result.selectedOptionIds,
      pairAnswers: result.pairAnswers,
      orderedItemIds: result.orderedItemIds,
    );
  }

  factory MiniGameProgressModel.fromJson(Map<String, dynamic> json) {
    final scoreJson = json['scoreImpact'];
    return MiniGameProgressModel(
      miniGameId: _readString(json['miniGameId']),
      chapterId: _readString(json['chapterId']),
      type: miniGameTypeFromJson(_readString(json['type'])),
      isSuccess: json['isSuccess'] == true,
      scoreImpact: scoreJson is Map<String, dynamic>
          ? ScoreModel.fromJson(scoreJson)
          : ScoreModel.zero,
      selectedOptionIds: _readStringSet(json['selectedOptionIds']),
      pairAnswers: _readStringMap(json['pairAnswers']),
      orderedItemIds: _readStringList(json['orderedItemIds']),
    );
  }

  static String _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return '';
  }

  static Set<String> _readStringSet(Object? value) {
    if (value is! List) {
      return <String>{};
    }
    return value.whereType<String>().toSet();
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().toList(growable: false);
  }

  static Map<String, String> _readStringMap(Object? value) {
    if (value is! Map) {
      return const <String, String>{};
    }
    return value.map<String, String>(
      (key, item) => MapEntry(key.toString(), item.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final selectedIds = selectedOptionIds.toList()..sort();
    return <String, dynamic>{
      'miniGameId': miniGameId,
      'chapterId': chapterId,
      'type': type.jsonValue,
      'isSuccess': isSuccess,
      'scoreImpact': scoreImpact.toJson(),
      'selectedOptionIds': selectedIds,
      'pairAnswers': pairAnswers,
      'orderedItemIds': orderedItemIds,
    };
  }
}
