import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/learning_analytics_model.dart';

void main() {
  test('Phase 33 analytics models parse events, dashboards, and privacy settings', () {
    final event = LearningAnalyticsEventModel.fromJson(<String, dynamic>{
      'id': 'event_1',
      'eventType': 'chapter_completed',
      'userId': 'user-1',
      'userHash': 'hash-only-for-admin',
      'roleId': 'developer',
      'chapterId': 'developer_login_button_disaster',
      'durationSeconds': 180,
      'scoreDelta': <String, dynamic>{'skill': 4, 'ethics': 2, 'communication': 1},
      'metadata': <String, dynamic>{'safeSurface': 'scenario_screen'},
      'createdAt': '2026-06-17T00:00:00.000Z',
    });
    expect(event.eventType, 'chapter_completed');
    expect(event.scoreDelta['skill'], 4);
    expect(event.durationSeconds, 180);

    final settings = LearningAnalyticsSettingsModel.fromJson(<String, dynamic>{
      'enabled': false,
      'shareAggregateWithAdmin': false,
      'retentionDays': 120,
    });
    expect(settings.enabled, isFalse);
    expect(settings.shareAggregateWithAdmin, isFalse);
    expect(settings.retentionDays, 120);

    final personal = PersonalAnalyticsDashboardModel.fromJson(<String, dynamic>{
      'userId': 'user-1',
      'analyticsEnabled': true,
      'generatedAt': '2026-06-17T00:00:00.000Z',
      'summary': <String, dynamic>{
        'totalEvents': 6,
        'totalChapterStarts': 1,
        'totalChapterCompletions': 1,
        'totalChoiceSelections': 1,
        'totalMiniGameAttempts': 1,
        'totalTimeSpentSeconds': 280,
        'averageCompletionPerRole': 100,
        'roleProgress': <String, dynamic>{
          'developer': <String, dynamic>{
            'roleId': 'developer',
            'chapterStarts': 1,
            'chapterCompletions': 1,
            'choices': 1,
            'miniGameAttempts': 1,
            'timeSpentSeconds': 280,
            'progressPercent': 100,
          },
        },
        'skillImprovement': <String, dynamic>{'skill': 7, 'communication': 3},
      },
      'recentEvents': <Map<String, dynamic>>[event.toJson()],
      'privacy': <String, dynamic>{
        'personalDashboardUsesOwnEventsOnly': true,
        'sensitiveMetadataFiltered': true,
      },
      'performance': <String, dynamic>{'aggregationMode': 'single_pass'},
    });

    expect(personal.summary.totalMiniGameAttempts, 1);
    expect(personal.summary.roleProgress['developer']?.progressPercent, 100);
    expect(personal.summary.skillImprovement['communication'], 3);
    expect(personal.privacy['sensitiveMetadataFiltered'], isTrue);

    final admin = AdminAnalyticsDashboardModel.fromJson(<String, dynamic>{
      'summary': <String, dynamic>{
        'totalEvents': 6,
        'totalChapterStarts': 1,
        'totalChapterCompletions': 1,
        'totalChoiceSelections': 1,
        'totalMiniGameAttempts': 1,
        'totalTimeSpentSeconds': 280,
        'averageCompletionPerRole': 100,
        'roleProgress': <String, dynamic>{},
        'skillImprovement': <String, dynamic>{'ethics': 2},
      },
      'eventCountsByType': <String, dynamic>{'chapter_completed': 1},
      'roleCounts': <String, dynamic>{'developer': 6},
      'privacy': <String, dynamic>{
        'rawUserIdsExposed': false,
        'aggregateOnly': true,
      },
      'performance': <String, dynamic>{
        'eventCount': 6,
        'aggregationMode': 'single_pass',
      },
    });

    expect(admin.eventCountsByType['chapter_completed'], 1);
    expect(admin.roleCounts['developer'], 6);
    expect(admin.privacy['rawUserIdsExposed'], isFalse);
  });
}
