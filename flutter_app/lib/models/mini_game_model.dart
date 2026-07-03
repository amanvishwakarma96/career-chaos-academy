import '../core/json_reader.dart';
import 'outcome_model.dart';
import 'score_model.dart';

enum MiniGameType {
  multipleSelect,
  codeFix,
  matchPairs,
  arrangeOrder,
  dataCleanup,
  decisionMatrix,
}

extension MiniGameTypeX on MiniGameType {
  String get jsonValue {
    switch (this) {
      case MiniGameType.multipleSelect:
        return 'multiple_select';
      case MiniGameType.codeFix:
        return 'code_fix';
      case MiniGameType.matchPairs:
        return 'match_pairs';
      case MiniGameType.arrangeOrder:
        return 'arrange_order';
      case MiniGameType.dataCleanup:
        return 'data_cleanup';
      case MiniGameType.decisionMatrix:
        return 'decision_matrix';
    }
  }

  String get label {
    switch (this) {
      case MiniGameType.multipleSelect:
        return 'Multiple Select';
      case MiniGameType.codeFix:
        return 'Code Fix';
      case MiniGameType.matchPairs:
        return 'Match Pairs';
      case MiniGameType.arrangeOrder:
        return 'Arrange Order';
      case MiniGameType.dataCleanup:
        return 'Data Cleanup';
      case MiniGameType.decisionMatrix:
        return 'Decision Matrix';
    }
  }

}


MiniGameType miniGameTypeFromJson(String value) {
  switch (value) {
    case 'multiple_select':
      return MiniGameType.multipleSelect;
    case 'code_fix':
      return MiniGameType.codeFix;
    case 'match_pairs':
      return MiniGameType.matchPairs;
    case 'arrange_order':
      return MiniGameType.arrangeOrder;
    case 'data_cleanup':
      return MiniGameType.dataCleanup;
    case 'decision_matrix':
      return MiniGameType.decisionMatrix;
    default:
      throw FormatException('miniGame.type "$value" is not supported.');
  }
}

class MiniGameOptionModel {
  final String id;
  final String text;
  final String? helperText;

  const MiniGameOptionModel({
    required this.id,
    required this.text,
    this.helperText,
  });

  factory MiniGameOptionModel.fromJson(
    Map<String, dynamic> json, {
    required String parent,
  }) {
    return MiniGameOptionModel(
      id: JsonReader.readString(json, 'id', parent: parent),
      text: JsonReader.readString(json, 'text', parent: parent),
      helperText: _readOptionalString(json['helperText']),
    );
  }

  static String? _readOptionalString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}

class MiniGamePairModel {
  final String leftId;
  final String leftText;
  final String rightId;
  final String rightText;

  const MiniGamePairModel({
    required this.leftId,
    required this.leftText,
    required this.rightId,
    required this.rightText,
  });

  factory MiniGamePairModel.fromJson(
    Map<String, dynamic> json, {
    required String parent,
  }) {
    return MiniGamePairModel(
      leftId: JsonReader.readString(json, 'leftId', parent: parent),
      leftText: JsonReader.readString(json, 'leftText', parent: parent),
      rightId: JsonReader.readString(json, 'rightId', parent: parent),
      rightText: JsonReader.readString(json, 'rightText', parent: parent),
    );
  }
}

class MiniGameModel {
  final String id;
  final MiniGameType type;
  final String title;
  final String instructions;
  final String prompt;
  final String hint;
  final List<MiniGameOptionModel> options;
  final Set<String> correctOptionIds;
  final List<MiniGamePairModel> pairs;
  final List<MiniGameOptionModel> orderItems;
  final List<String> correctOrderIds;
  final ScoreModel successScoreImpact;
  final ScoreModel failureScoreImpact;
  final String successMessage;
  final String failureMessage;
  final OutcomeModel successConsequence;
  final OutcomeModel failureConsequence;
  final String skillLevel;
  final String workflowId;
  final List<String> skillTags;
  final List<String> skillNodeIds;

  const MiniGameModel({
    required this.id,
    required this.type,
    required this.title,
    required this.instructions,
    required this.prompt,
    required this.hint,
    this.options = const <MiniGameOptionModel>[],
    this.correctOptionIds = const <String>{},
    this.pairs = const <MiniGamePairModel>[],
    this.orderItems = const <MiniGameOptionModel>[],
    this.correctOrderIds = const <String>[],
    this.successScoreImpact = ScoreModel.zero,
    this.failureScoreImpact = ScoreModel.zero,
    required this.successMessage,
    required this.failureMessage,
    this.successConsequence = const OutcomeModel(
      title: 'Mini-game cleared',
      description: 'Your professional challenge result was saved.',
      moralLesson: 'Practice improves judgment.',
    ),
    this.failureConsequence = const OutcomeModel(
      title: 'Mini-game needs cleanup',
      description: 'The challenge result created extra learning work.',
      moralLesson: 'Mistakes are useful when they lead to remediation.',
    ),
    this.skillLevel = 'beginner',
    this.workflowId = '',
    this.skillTags = const <String>[],
    this.skillNodeIds = const <String>[],
  });

  factory MiniGameModel.fromJson(Map<String, dynamic> json) {
    final typeText = JsonReader.readString(json, 'type', parent: 'miniGame');
    final type = miniGameTypeFromJson(typeText);
    final options = _readOptions(json['options']);
    final pairs = _readPairs(json['pairs']);
    final orderItems = _readOptions(json['orderItems']);

    final miniGame = MiniGameModel(
      id: JsonReader.readString(json, 'id', parent: 'miniGame'),
      type: type,
      title: JsonReader.readString(json, 'title', parent: 'miniGame'),
      instructions: JsonReader.readString(
        json,
        'instructions',
        parent: 'miniGame',
      ),
      prompt: JsonReader.readString(json, 'prompt', parent: 'miniGame'),
      hint: JsonReader.readString(json, 'hint', parent: 'miniGame'),
      options: options,
      correctOptionIds: _readStringSet(json['correctOptionIds']),
      pairs: pairs,
      orderItems: orderItems,
      correctOrderIds: _readStringList(json['correctOrderIds']),
      successScoreImpact: _readScore(
        json['successScoreImpact'],
        parent: 'miniGame.successScoreImpact',
      ),
      failureScoreImpact: _readScore(
        json['failureScoreImpact'],
        parent: 'miniGame.failureScoreImpact',
      ),
      successMessage: JsonReader.readString(
        json,
        'successMessage',
        parent: 'miniGame',
      ),
      failureMessage: JsonReader.readString(
        json,
        'failureMessage',
        parent: 'miniGame',
      ),
      successConsequence: _readConsequence(
        json['successConsequence'],
        fallbackTitle: 'Mini-game cleared',
        fallbackDescription: JsonReader.readString(
          json,
          'successMessage',
          parent: 'miniGame',
        ),
      ),
      failureConsequence: _readConsequence(
        json['failureConsequence'],
        fallbackTitle: 'Mini-game failed',
        fallbackDescription: JsonReader.readString(
          json,
          'failureMessage',
          parent: 'miniGame',
        ),
      ),
      skillLevel: _readOptionalString(json['skillLevel']) ?? 'beginner',
      workflowId: _readOptionalString(json['workflowId']) ?? '',
      skillTags: _readStringList(json['skillTags']),
      skillNodeIds: _readStringList(json['skillNodeIds']),
    );

    miniGame._validateShape();
    return miniGame;
  }

  static List<MiniGameOptionModel> _readOptions(Object? value) {
    if (value == null) {
      return const <MiniGameOptionModel>[];
    }
    if (value is! List) {
      throw const FormatException('miniGame.options must be a list.');
    }

    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('miniGame option item must be an object.');
      }
      return MiniGameOptionModel.fromJson(item, parent: 'miniGame.option');
    }).toList(growable: false);
  }

  static List<MiniGamePairModel> _readPairs(Object? value) {
    if (value == null) {
      return const <MiniGamePairModel>[];
    }
    if (value is! List) {
      throw const FormatException('miniGame.pairs must be a list.');
    }

    return value.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('miniGame pair item must be an object.');
      }
      return MiniGamePairModel.fromJson(item, parent: 'miniGame.pair');
    }).toList(growable: false);
  }

  static Set<String> _readStringSet(Object? value) {
    if (value == null) {
      return const <String>{};
    }
    if (value is! List) {
      throw const FormatException('miniGame.correctOptionIds must be a list.');
    }
    final items = value.whereType<String>().map((item) => item.trim()).where(
          (item) => item.isNotEmpty,
        );
    return Set<String>.unmodifiable(items);
  }

  static List<String> _readStringList(Object? value) {
    if (value == null) {
      return const <String>[];
    }
    if (value is! List) {
      throw const FormatException('miniGame.correctOrderIds must be a list.');
    }
    return value.whereType<String>().map((item) => item.trim()).where(
      (item) => item.isNotEmpty,
    ).toList(growable: false);
  }

  static ScoreModel _readScore(Object? value, {required String parent}) {
    if (value == null) {
      return ScoreModel.zero;
    }
    if (value is! Map<String, dynamic>) {
      throw FormatException('$parent must be an object.');
    }
    return ScoreModel.fromJson(value);
  }


  static OutcomeModel _readConsequence(
    Object? value, {
    required String fallbackTitle,
    required String fallbackDescription,
  }) {
    if (value is Map<String, dynamic>) {
      return OutcomeModel.fromJson(<String, dynamic>{
        'title': fallbackTitle,
        'description': fallbackDescription,
        'moralLesson': 'Mini-game performance affects professional consequences.',
        ...value,
      });
    }
    return OutcomeModel(
      title: fallbackTitle,
      description: fallbackDescription,
      moralLesson: 'Mini-game performance affects professional consequences.',
    );
  }
  void _validateShape() {
    switch (type) {
      case MiniGameType.codeFix:
      case MiniGameType.multipleSelect:
      case MiniGameType.dataCleanup:
      case MiniGameType.decisionMatrix:
        if (options.isEmpty || correctOptionIds.isEmpty) {
          throw FormatException(
            'miniGame $id requires options and correctOptionIds.',
          );
        }
        return;
      case MiniGameType.matchPairs:
        if (pairs.isEmpty) {
          throw FormatException('miniGame $id requires pairs.');
        }
        return;
      case MiniGameType.arrangeOrder:
        if (orderItems.isEmpty || correctOrderIds.isEmpty) {
          throw FormatException(
            'miniGame $id requires orderItems and correctOrderIds.',
          );
        }
        return;
    }
  }
}
