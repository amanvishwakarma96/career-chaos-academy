import 'package:flutter/foundation.dart';

import '../../models/future_scope/analytics_event_model.dart';
import '../release_monitoring_service.dart';

class AnalyticsEventService {
  AnalyticsEventService._();

  static final AnalyticsEventService instance = AnalyticsEventService._();

  final ValueNotifier<List<AnalyticsEventModel>> recentEvents =
      ValueNotifier<List<AnalyticsEventModel>>(const <AnalyticsEventModel>[]);

  Future<void> track(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    final event = AnalyticsEventModel(name: name, parameters: parameters);
    final next = <AnalyticsEventModel>[event, ...recentEvents.value];
    recentEvents.value = List<AnalyticsEventModel>.unmodifiable(next.take(50));

    final sanitized = <String, Object>{};
    parameters.forEach((key, value) {
      sanitized[key] = value ?? '';
    });
    await ReleaseMonitoringService.instance.logEvent(name, parameters: sanitized);
  }
}
