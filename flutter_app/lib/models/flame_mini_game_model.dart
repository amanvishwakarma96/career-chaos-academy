import 'score_model.dart';

enum FlameMiniGameKind {
  bugHuntRoom,
  dataCleanupRace,
  blueprintSafetyPuzzle,
}

extension FlameMiniGameKindLabel on FlameMiniGameKind {
  String get id {
    switch (this) {
      case FlameMiniGameKind.bugHuntRoom:
        return 'bug_hunt_room';
      case FlameMiniGameKind.dataCleanupRace:
        return 'data_cleanup_race';
      case FlameMiniGameKind.blueprintSafetyPuzzle:
        return 'blueprint_safety_puzzle';
    }
  }

  String get label {
    switch (this) {
      case FlameMiniGameKind.bugHuntRoom:
        return 'Bug Hunt Room';
      case FlameMiniGameKind.dataCleanupRace:
        return 'Data Cleanup Race';
      case FlameMiniGameKind.blueprintSafetyPuzzle:
        return 'Blueprint Safety Puzzle';
    }
  }
}


FlameMiniGameKind flameMiniGameKindFromId(String? value) {
  for (final kind in FlameMiniGameKind.values) {
    if (kind.id == value) {
      return kind;
    }
  }
  return FlameMiniGameKind.bugHuntRoom;
}

class FlameMiniGameTargetModel {
  final String id;
  final String label;
  final String hint;
  final bool isCorrect;
  final String feedback;

  const FlameMiniGameTargetModel({
    required this.id,
    required this.label,
    required this.hint,
    required this.isCorrect,
    required this.feedback,
  });
}

class FlameMiniGameDefinitionModel {
  final String id;
  final FlameMiniGameKind kind;
  final String title;
  final String subtitle;
  final String instructions;
  final int timeLimitSeconds;
  final int successThreshold;
  final ScoreModel successScoreImpact;
  final ScoreModel failureScoreImpact;
  final int successXp;
  final int failureXp;
  final String successMessage;
  final String failureMessage;
  final List<FlameMiniGameTargetModel> targets;

  const FlameMiniGameDefinitionModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.instructions,
    required this.timeLimitSeconds,
    required this.successThreshold,
    required this.successScoreImpact,
    required this.failureScoreImpact,
    required this.successXp,
    required this.failureXp,
    required this.successMessage,
    required this.failureMessage,
    required this.targets,
  });

  int get correctTargetCount => targets.where((target) => target.isCorrect).length;
}

class FlameMiniGameResultModel {
  final String gameId;
  final FlameMiniGameKind kind;
  final String title;
  final DateTime completedAt;
  final bool isSuccess;
  final int correctCount;
  final int wrongCount;
  final int elapsedSeconds;
  final int xpEarned;
  final ScoreModel scoreImpact;
  final Set<String> selectedTargetIds;
  final String message;

  const FlameMiniGameResultModel({
    required this.gameId,
    required this.kind,
    required this.title,
    required this.completedAt,
    required this.isSuccess,
    required this.correctCount,
    required this.wrongCount,
    required this.elapsedSeconds,
    required this.xpEarned,
    required this.scoreImpact,
    required this.selectedTargetIds,
    required this.message,
  });

  factory FlameMiniGameResultModel.fromJson(Map<String, dynamic> json) {
    return FlameMiniGameResultModel(
      gameId: _readString(json['gameId']),
      kind: flameMiniGameKindFromId(json['kind'] as String?),
      title: _readString(json['title'], fallback: 'Flame Mini-game'),
      completedAt: DateTime.tryParse(_readString(json['completedAt'])) ?? DateTime.fromMillisecondsSinceEpoch(0),
      isSuccess: json['isSuccess'] == true,
      correctCount: _readInt(json['correctCount']),
      wrongCount: _readInt(json['wrongCount']),
      elapsedSeconds: _readInt(json['elapsedSeconds']),
      xpEarned: _readInt(json['xpEarned']),
      scoreImpact: json['scoreImpact'] is Map<String, dynamic>
          ? ScoreModel.fromJson(json['scoreImpact'] as Map<String, dynamic>)
          : ScoreModel.zero,
      selectedTargetIds: _readStringSet(json['selectedTargetIds']),
      message: _readString(json['message']),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static Set<String> _readStringSet(Object? value) {
    if (value is! List) {
      return <String>{};
    }
    return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toSet();
  }

  Map<String, dynamic> toJson() {
    final selected = selectedTargetIds.toList()..sort();
    return <String, dynamic>{
      'gameId': gameId,
      'kind': kind.id,
      'title': title,
      'completedAt': completedAt.toIso8601String(),
      'isSuccess': isSuccess,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'elapsedSeconds': elapsedSeconds,
      'xpEarned': xpEarned,
      'scoreImpact': scoreImpact.toJson(),
      'selectedTargetIds': selected,
      'message': message,
    };
  }
}
