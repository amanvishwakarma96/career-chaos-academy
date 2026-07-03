import 'dart:async';
import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../core/app_metadata.dart';

class ReleaseMonitoringService {
  ReleaseMonitoringService._();

  static final ReleaseMonitoringService instance = ReleaseMonitoringService._();

  static const bool _enableSentry = bool.fromEnvironment(
    'CAREER_CHAOS_ENABLE_SENTRY',
    defaultValue: false,
  );
  static const bool _enableFirebaseAnalytics = bool.fromEnvironment(
    'CAREER_CHAOS_ENABLE_FIREBASE_ANALYTICS',
    defaultValue: false,
  );
  static const String _sentryDsn = String.fromEnvironment(
    'CAREER_CHAOS_SENTRY_DSN',
    defaultValue: '',
  );

  FirebaseAnalytics? _analytics;
  bool _sentryReady = false;
  bool _analyticsReady = false;

  bool get isCrashReportingEnabled => _sentryReady;
  bool get isAnalyticsEnabled => _analyticsReady;

  List<NavigatorObserver> get navigatorObservers {
    final analytics = _analytics;
    if (analytics == null) {
      return const <NavigatorObserver>[];
    }
    return <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: analytics),
    ];
  }

  Future<void> initialize() async {
    await _initializeCrashReporting();
    await _initializeAnalytics();
    _attachGlobalErrorHandlers();
  }

  Future<void> _initializeCrashReporting() async {
    if (!_enableSentry || _sentryDsn.trim().isEmpty) {
      debugPrint('Crash reporting disabled. Provide CAREER_CHAOS_ENABLE_SENTRY=true and CAREER_CHAOS_SENTRY_DSN to enable it.');
      return;
    }

    try {
      await SentryFlutter.init((options) {
        options.dsn = _sentryDsn;
        options.release = '${AppMetadata.packageName}@${AppMetadata.versionName}+${AppMetadata.versionCode}';
        options.environment = kReleaseMode ? 'production' : 'development';
        options.tracesSampleRate = kReleaseMode ? 0.10 : 1.0;
        options.enableAutoSessionTracking = true;
      });
      _sentryReady = true;
    } catch (error, stackTrace) {
      debugPrint('Crash reporting initialization failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  Future<void> _initializeAnalytics() async {
    if (!_enableFirebaseAnalytics) {
      debugPrint('Analytics disabled. Provide CAREER_CHAOS_ENABLE_FIREBASE_ANALYTICS=true after FlutterFire setup to enable it.');
      return;
    }

    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      await _analytics?.setAnalyticsCollectionEnabled(true);
      _analyticsReady = true;
    } catch (error, stackTrace) {
      debugPrint('Analytics initialization failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  void _attachGlobalErrorHandlers() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutterHandler?.call(details);
      unawaited(recordError(
        details.exception,
        details.stack ?? StackTrace.current,
        fatal: true,
      ));
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(recordError(error, stackTrace, fatal: true));
      return false;
    };
  }

  Future<void> logAppStart() async {
    await logEvent('app_start', parameters: <String, Object>{
      'version_name': AppMetadata.versionName,
      'version_code': AppMetadata.versionCode,
    });
  }

  Future<void> logChapterCompleted({
    required String roleId,
    required String chapterId,
    required int xpGained,
    required int totalXp,
    required int totalScore,
  }) async {
    await logEvent('chapter_completed', parameters: <String, Object>{
      'role_id': roleId,
      'chapter_id': chapterId,
      'xp_gained': xpGained,
      'total_xp': totalXp,
      'total_score': totalScore,
    });
  }

  Future<void> logMiniGameCompleted({
    required String roleId,
    required String chapterId,
    required String miniGameId,
    required bool passed,
    required int scoreImpact,
  }) async {
    await logEvent('mini_game_completed', parameters: <String, Object>{
      'role_id': roleId,
      'chapter_id': chapterId,
      'mini_game_id': miniGameId,
      'passed': passed,
      'score_impact': scoreImpact,
    });
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    final analytics = _analytics;
    if (analytics == null) {
      if (kDebugMode) {
        debugPrint('Analytics event skipped: $name ${parameters ?? <String, Object>{}}');
      }
      return;
    }

    await analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    if (!_sentryReady) {
      if (kDebugMode) {
        debugPrint('Crash report skipped: $error');
      }
      return;
    }

    await Sentry.captureException(error, stackTrace: stackTrace);
  }
}
