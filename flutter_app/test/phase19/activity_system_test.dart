import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/activity_model.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:career_chaos_academy/services/activity_service.dart';

void main() {
  group('Phase 19 activity system', () {
    test('parses activity JSON with timer, rewards, and answers', () {
      final activity = ActivityModel.fromJson(const <String, dynamic>{
        'id': 'daily_dev_triage',
        'type': 'daily_challenge',
        'title': 'Daily Chaos Triage',
        'prompt': 'Choose one.',
        'options': ['safe', 'chaos'],
        'correctAnswers': ['safe'],
        'durationSeconds': 45,
        'rewardXp': 90,
        'rewardBadgeId': 'daily_chaos_starter',
      });

      expect(activity.isTimed, isTrue);
      expect(activity.rewardXp, 90);
      expect(activity.correctAnswers, contains('safe'));
    });

    test('evaluates correct and wrong answers differently', () {
      final activity = ActivityModel.fromJson(const <String, dynamic>{
        'id': 'bug_hunt',
        'type': 'bug_hunt',
        'title': 'Bug Hunt',
        'prompt': 'Pick evidence.',
        'options': ['steps', 'screenshot', 'guess'],
        'correctAnswers': ['steps', 'screenshot'],
        'durationSeconds': 60,
        'rewardXp': 100,
        'successMessage': 'Captured.',
        'failureMessage': 'Weak evidence.',
      });

      final success = ActivityService.instance.evaluate(
        activity: activity,
        selectedAnswers: {'steps', 'screenshot'},
        secondsRemaining: 10,
      );
      final failure = ActivityService.instance.evaluate(
        activity: activity,
        selectedAnswers: {'guess'},
        secondsRemaining: 10,
      );

      expect(success.isSuccess, isTrue);
      expect(success.xpEarned, 100);
      expect(failure.isSuccess, isFalse);
      expect(failure.xpEarned, lessThan(success.xpEarned));
    });

    test('activity history, streak, and xp remain backward compatible', () {
      final oldSnapshot = ProgressSnapshotModel.fromJson(const <String, dynamic>{
        'version': 5,
        'progressByRole': {},
        'totalXp': 0,
      });
      expect(oldSnapshot.activityHistory, isEmpty);
      expect(oldSnapshot.activityStreak.currentStreak, 0);
      expect(oldSnapshot.activityXp, 0);

      final snapshot = ProgressSnapshotModel.fromJson(<String, dynamic>{
        'version': 6,
        'progressByRole': {},
        'totalXp': 90,
        'activityXp': 90,
        'activityStreak': const {'currentStreak': 1, 'longestStreak': 1, 'lastCompletionDate': '2026-06-16'},
        'activityHistory': [
          {
            'activityId': 'daily_dev_triage',
            'activityType': 'daily_challenge',
            'title': 'Daily Chaos Triage',
            'completedAt': DateTime(2026, 6, 16).toIso8601String(),
            'isSuccess': true,
            'score': 100,
            'xpEarned': 90,
            'streakAfter': 1,
            'feedback': 'Good triage!',
          }
        ],
      });

      expect(snapshot.activityHistory.length, 1);
      expect(snapshot.activityStreak.currentStreak, 1);
      expect(snapshot.toJson()['activityXp'], 90);
    });
  });
}
