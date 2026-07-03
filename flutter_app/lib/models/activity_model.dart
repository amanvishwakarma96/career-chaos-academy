class ActivityModel {
  final String id;
  final String type;
  final String title;
  final String roleId;
  final String difficulty;
  final String description;
  final String prompt;
  final List<String> options;
  final Set<String> correctAnswers;
  final int durationSeconds;
  final int rewardXp;
  final String rewardBadgeId;
  final String successMessage;
  final String failureMessage;
  final String learningPoint;
  final String practicalTakeaway;
  final bool weeklyPlaceholder;

  const ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    this.roleId = '',
    this.difficulty = 'Beginner',
    this.description = '',
    required this.prompt,
    this.options = const <String>[],
    this.correctAnswers = const <String>{},
    this.durationSeconds = 0,
    this.rewardXp = 0,
    this.rewardBadgeId = '',
    this.successMessage = '',
    this.failureMessage = '',
    this.learningPoint = '',
    this.practicalTakeaway = '',
    this.weeklyPlaceholder = false,
  });

  bool get isTimed => durationSeconds > 0;
  bool get allowsMultipleSelection => <String>{
        'bug_hunt',
        'data_cleanup_race',
        'ethical_dilemma',
      }.contains(type) || correctAnswers.length > 1;

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: _readString(json['id']),
      type: _readString(json['type'], fallback: 'role_quiz'),
      title: _readString(json['title'], fallback: 'Untitled Activity'),
      roleId: _readString(json['roleId']),
      difficulty: _readString(json['difficulty'], fallback: 'Beginner'),
      description: _readString(json['description']),
      prompt: _readString(json['prompt'], fallback: 'Choose the best response.'),
      options: _readStringList(json['options']),
      correctAnswers: _readStringList(json['correctAnswers']).toSet(),
      durationSeconds: _readInt(json['durationSeconds']),
      rewardXp: _readInt(json['rewardXp']),
      rewardBadgeId: _readString(json['rewardBadgeId']),
      successMessage: _readString(json['successMessage'], fallback: 'Nice work!'),
      failureMessage: _readString(json['failureMessage'], fallback: 'Funny failure, useful lesson.'),
      learningPoint: _readString(json['learningPoint']),
      practicalTakeaway: _readString(json['practicalTakeaway']),
      weeklyPlaceholder: json['weeklyPlaceholder'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'title': title,
      'roleId': roleId,
      'difficulty': difficulty,
      'description': description,
      'prompt': prompt,
      'options': options,
      'correctAnswers': correctAnswers.toList()..sort(),
      'durationSeconds': durationSeconds,
      'rewardXp': rewardXp,
      'rewardBadgeId': rewardBadgeId,
      'successMessage': successMessage,
      'failureMessage': failureMessage,
      'learningPoint': learningPoint,
      'practicalTakeaway': practicalTakeaway,
      'weeklyPlaceholder': weeklyPlaceholder,
    };
  }
}

class ActivityHistoryModel {
  final String activityId;
  final String activityType;
  final String title;
  final DateTime completedAt;
  final bool isSuccess;
  final int score;
  final int xpEarned;
  final int streakAfter;
  final String feedback;

  const ActivityHistoryModel({
    required this.activityId,
    required this.activityType,
    required this.title,
    required this.completedAt,
    required this.isSuccess,
    required this.score,
    required this.xpEarned,
    required this.streakAfter,
    required this.feedback,
  });

  factory ActivityHistoryModel.fromJson(Map<String, dynamic> json) {
    return ActivityHistoryModel(
      activityId: _readString(json['activityId']),
      activityType: _readString(json['activityType']),
      title: _readString(json['title']),
      completedAt: DateTime.tryParse(_readString(json['completedAt'])) ?? DateTime.fromMillisecondsSinceEpoch(0),
      isSuccess: json['isSuccess'] == true,
      score: _readInt(json['score']),
      xpEarned: _readInt(json['xpEarned']),
      streakAfter: _readInt(json['streakAfter']),
      feedback: _readString(json['feedback']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'activityId': activityId,
      'activityType': activityType,
      'title': title,
      'completedAt': completedAt.toIso8601String(),
      'isSuccess': isSuccess,
      'score': score,
      'xpEarned': xpEarned,
      'streakAfter': streakAfter,
      'feedback': feedback,
    };
  }
}

class ActivityStreakModel {
  final int currentStreak;
  final int longestStreak;
  final String? lastCompletionDate;

  const ActivityStreakModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletionDate,
  });

  static const ActivityStreakModel zero = ActivityStreakModel();

  factory ActivityStreakModel.fromJson(Map<String, dynamic> json) {
    return ActivityStreakModel(
      currentStreak: _readInt(json['currentStreak']),
      longestStreak: _readInt(json['longestStreak']),
      lastCompletionDate: _readString(json['lastCompletionDate']).isEmpty ? null : _readString(json['lastCompletionDate']),
    );
  }

  ActivityStreakModel recordSuccess(DateTime completedAt) {
    final today = _dateKey(completedAt);
    if (lastCompletionDate == today) {
      return this;
    }

    final yesterday = _dateKey(completedAt.subtract(const Duration(days: 1)));
    final nextCurrent = lastCompletionDate == yesterday ? currentStreak + 1 : 1;
    return ActivityStreakModel(
      currentStreak: nextCurrent,
      longestStreak: nextCurrent > longestStreak ? nextCurrent : longestStreak,
      lastCompletionDate: today,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletionDate': lastCompletionDate,
    };
  }

  static String _dateKey(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class ActivityCompletionResultModel {
  final ActivityHistoryModel history;
  final ActivityStreakModel streak;
  final int totalXp;

  const ActivityCompletionResultModel({
    required this.history,
    required this.streak,
    required this.totalXp,
  });
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

int _readInt(Object? value) {
  if (value is int) return value < 0 ? 0 : value;
  if (value is num) return value.toInt() < 0 ? 0 : value.toInt();
  return 0;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList(growable: false);
}
