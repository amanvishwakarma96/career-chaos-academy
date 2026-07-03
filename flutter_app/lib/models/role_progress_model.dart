import 'mini_game_progress_model.dart';
import 'mini_game_result_model.dart';
import 'scenario_model.dart';
import 'score_model.dart';

enum ChapterProgressState { completed, current, locked, blocked }

class RoleProgressModel {
  final String roleId;
  final Set<String> completedChapterIds;
  final int unlockedChapterIndex;
  final ScoreModel roleScore;
  final int roleXp;
  final Set<String> badges;
  final Map<String, MiniGameProgressModel> miniGameResults;

  const RoleProgressModel({
    required this.roleId,
    this.completedChapterIds = const <String>{},
    this.unlockedChapterIndex = 0,
    this.roleScore = ScoreModel.zero,
    this.roleXp = 0,
    this.badges = const <String>{},
    this.miniGameResults = const <String, MiniGameProgressModel>{},
  });

  factory RoleProgressModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackRoleId,
  }) {
    final completedItems = json['completedChapterIds'];
    final badgeItems = json['badges'];
    final scoreJson = json['roleScore'];

    return RoleProgressModel(
      roleId: _readString(json['roleId'], fallbackRoleId),
      completedChapterIds: _readStringSet(completedItems),
      unlockedChapterIndex: _readInt(json['unlockedChapterIndex']),
      roleScore: scoreJson is Map<String, dynamic>
          ? ScoreModel.fromJson(scoreJson)
          : ScoreModel.zero,
      roleXp: _readInt(json['roleXp']),
      badges: _readStringSet(badgeItems),
      miniGameResults: _readMiniGameResults(json['miniGameResults']),
    );
  }

  static String _readString(Object? value, String fallback) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return fallback;
  }

  static int _readInt(Object? value) {
    if (value is int && value >= 0) {
      return value;
    }
    return 0;
  }

  static Set<String> _readStringSet(Object? value) {
    if (value is! List) {
      return <String>{};
    }

    return value.whereType<String>().toSet();
  }

  static Map<String, MiniGameProgressModel> _readMiniGameResults(
    Object? value,
  ) {
    if (value is! Map) {
      return const <String, MiniGameProgressModel>{};
    }

    final results = <String, MiniGameProgressModel>{};
    value.forEach((_, item) {
      if (item is Map<String, dynamic>) {
        try {
          final result = MiniGameProgressModel.fromJson(item);
          if (result.miniGameId.isNotEmpty) {
            results[result.miniGameId] = result;
          }
        } on Object {
          // Ignore corrupt mini-game entries and keep the rest of progress safe.
        }
      }
    });

    return Map<String, MiniGameProgressModel>.unmodifiable(results);
  }

  Map<String, dynamic> toJson() {
    final completedIds = completedChapterIds.toList()..sort();
    final badgeList = badges.toList()..sort();

    return <String, dynamic>{
      'roleId': roleId,
      'completedChapterIds': completedIds,
      'unlockedChapterIndex': unlockedChapterIndex,
      'roleScore': roleScore.toJson(),
      'roleXp': roleXp,
      'badges': badgeList,
      'miniGameResults': miniGameResults.map(
        (miniGameId, result) => MapEntry(miniGameId, result.toJson()),
      ),
    };
  }

  bool isChapterCompleted(String chapterId) {
    return completedChapterIds.contains(chapterId);
  }

  bool isChapterUnlocked(int chapterIndex) {
    return chapterIndex <= unlockedChapterIndex;
  }

  bool isMiniGameCompleted(String miniGameId) {
    return miniGameResults.containsKey(miniGameId);
  }

  ChapterProgressState chapterState(int chapterIndex, String chapterId) {
    if (isChapterCompleted(chapterId)) {
      return ChapterProgressState.completed;
    }

    if (!isChapterUnlocked(chapterIndex)) {
      return ChapterProgressState.locked;
    }

    return ChapterProgressState.current;
  }

  double progressPercent(int totalChapters) {
    if (totalChapters <= 0) {
      return 0;
    }

    return (completedChapterIds.length / totalChapters).clamp(0, 1).toDouble();
  }

  RoleProgressModel completeChapter({
    required List<ScenarioModel> chapters,
    required ScenarioModel completedChapter,
    required ScoreModel scoreImpact,
    required int xpGained,
    Set<String> unlockedBadgeIds = const <String>{},
  }) {
    final alreadyCompleted = isChapterCompleted(completedChapter.id);
    final completedIds = Set<String>.from(completedChapterIds)
      ..add(completedChapter.id);
    final completedIndex = chapters.indexWhere(
      (chapter) => chapter.id == completedChapter.id,
    );

    final nextUnlockedIndex = completedIndex < 0
        ? unlockedChapterIndex
        : (completedIndex + 1).clamp(0, chapters.length - 1).toInt();

    final updatedBadges = Set<String>.from(badges)..addAll(unlockedBadgeIds);

    return copyWith(
      completedChapterIds: completedIds,
      unlockedChapterIndex: nextUnlockedIndex > unlockedChapterIndex
          ? nextUnlockedIndex
          : unlockedChapterIndex,
      roleScore: alreadyCompleted ? roleScore : roleScore.add(scoreImpact),
      roleXp: alreadyCompleted ? roleXp : roleXp + xpGained,
      badges: updatedBadges,
    );
  }

  RoleProgressModel recordMiniGameResult({
    required String chapterId,
    required MiniGameResultModel result,
  }) {
    if (miniGameResults.containsKey(result.miniGameId)) {
      return this;
    }

    final updatedMiniGameResults = Map<String, MiniGameProgressModel>.from(
      miniGameResults,
    )..[result.miniGameId] = MiniGameProgressModel.fromResult(
        chapterId: chapterId,
        result: result,
      );

    return copyWith(
      roleScore: roleScore.add(result.scoreImpact),
      miniGameResults: updatedMiniGameResults,
    );
  }

  RoleProgressModel copyWith({
    Set<String>? completedChapterIds,
    int? unlockedChapterIndex,
    ScoreModel? roleScore,
    int? roleXp,
    Set<String>? badges,
    Map<String, MiniGameProgressModel>? miniGameResults,
  }) {
    return RoleProgressModel(
      roleId: roleId,
      completedChapterIds: completedChapterIds ?? this.completedChapterIds,
      unlockedChapterIndex: unlockedChapterIndex ?? this.unlockedChapterIndex,
      roleScore: roleScore ?? this.roleScore,
      roleXp: roleXp ?? this.roleXp,
      badges: badges ?? this.badges,
      miniGameResults: miniGameResults ?? this.miniGameResults,
    );
  }
}
