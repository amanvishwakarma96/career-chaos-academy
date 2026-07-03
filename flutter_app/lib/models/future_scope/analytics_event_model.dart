class AnalyticsEventModel {
  final String name;
  final Map<String, Object?> parameters;
  final DateTime createdAt;

  AnalyticsEventModel({
    required this.name,
    this.parameters = const <String, Object?>{},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'parameters': parameters,
        'createdAt': createdAt.toIso8601String(),
      };
}

class AnalyticsEvents {
  const AnalyticsEvents._();

  static const appStarted = 'app_started';
  static const roleSelected = 'role_selected';
  static const chapterStarted = 'chapter_started';
  static const chapterCompleted = 'chapter_completed';
  static const choiceSelected = 'choice_selected';
  static const miniGameStarted = 'mini_game_started';
  static const miniGameCompleted = 'mini_game_completed';
  static const activityCompleted = 'activity_completed';
  static const mentorFeedbackViewed = 'mentor_feedback_viewed';
  static const contentPackLoaded = 'content_pack_loaded';
  static const safetyReviewBlockedPublish = 'safety_review_blocked_publish';
}
