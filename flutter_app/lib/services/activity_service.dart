import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/activity_model.dart';
import 'api_client.dart';

class ActivityLoadResult {
  final List<ActivityModel> activities;
  final List<String> errors;

  const ActivityLoadResult({
    required this.activities,
    this.errors = const <String>[],
  });

  bool get hasActivities => activities.isNotEmpty;
}

class ActivityEvaluationResult {
  final bool isSuccess;
  final int score;
  final int xpEarned;
  final String feedback;

  const ActivityEvaluationResult({
    required this.isSuccess,
    required this.score,
    required this.xpEarned,
    required this.feedback,
  });
}

class ActivityService {
  ActivityService._();

  static final ActivityService instance = ActivityService._();
  static const String _assetPath = 'assets/game/activities/activities.json';

  Future<ActivityLoadResult> loadActivities() async {
    final remote = await _loadRemoteActivities();
    if (remote != null && remote.hasActivities) {
      return remote;
    }

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const ActivityLoadResult(
          activities: <ActivityModel>[],
          errors: <String>['Activity JSON root must be an object.'],
        );
      }
      return _parseActivityMap(decoded);
    } catch (error) {
      return ActivityLoadResult(
        activities: const <ActivityModel>[],
        errors: <String>['Failed to load activities: $error'],
      );
    }
  }


  Future<ActivityLoadResult?> _loadRemoteActivities() async {
    if (!ApiClient.instance.isEnabled) {
      return null;
    }
    try {
      final decoded = await ApiClient.instance.getMap('/api/activities');
      return _parseActivityMap(decoded);
    } on Object {
      return null;
    }
  }

  ActivityLoadResult _parseActivityMap(Map<String, dynamic> decoded) {
    final items = decoded['activities'];
    if (items is! List) {
      return const ActivityLoadResult(
        activities: <ActivityModel>[],
        errors: <String>['Activity JSON must contain activities list.'],
      );
    }
    final activities = <ActivityModel>[];
    final errors = <String>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      try {
        final activity = ActivityModel.fromJson(item);
        if (activity.id.isEmpty) {
          errors.add('Skipped activity with empty id.');
        } else {
          activities.add(activity);
        }
      } catch (error) {
        errors.add(error.toString());
      }
    }
    return ActivityLoadResult(activities: activities, errors: errors);
  }

  ActivityEvaluationResult evaluate({
    required ActivityModel activity,
    required Set<String> selectedAnswers,
    required int secondsRemaining,
  }) {
    if (activity.weeklyPlaceholder) {
      return ActivityEvaluationResult(
        isSuccess: false,
        score: 0,
        xpEarned: 0,
        feedback: activity.failureMessage,
      );
    }

    final expected = activity.correctAnswers;
    final matched = selectedAnswers.intersection(expected).length;
    final wrong = selectedAnswers.difference(expected).length;
    final missed = expected.difference(selectedAnswers).length;
    final baseScore = ((matched * 100) / (expected.isEmpty ? 1 : expected.length)).round();
    final penalty = wrong * 20 + missed * 10;
    final timedBonus = activity.isTimed && secondsRemaining > 0 ? 5 : 0;
    final score = (baseScore - penalty + timedBonus).clamp(0, 100).toInt();
    final isSuccess = selectedAnswers.length == expected.length && wrong == 0 && missed == 0;
    final xpEarned = isSuccess ? activity.rewardXp : (activity.rewardXp * 0.25).round();

    return ActivityEvaluationResult(
      isSuccess: isSuccess,
      score: score,
      xpEarned: xpEarned,
      feedback: isSuccess ? activity.successMessage : activity.failureMessage,
    );
  }
}
