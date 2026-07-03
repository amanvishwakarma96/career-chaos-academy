import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/future_scope/remote_config_model.dart';

class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  final ValueNotifier<RemoteConfigModel> config =
      ValueNotifier<RemoteConfigModel>(const RemoteConfigModel());

  Future<void> loadDefaults() async {
    try {
      final raw = await rootBundle.loadString('assets/config/remote_config_defaults.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        config.value = RemoteConfigModel.fromJson(decoded);
      }
    } catch (_) {
      config.value = const RemoteConfigModel();
    }
  }

  T? getValue<T>(String key) => config.value.value<T>(key);

  Future<void> fetchRemotePlaceholder() async {
    // Future integration point for Firebase Remote Config or API-driven config.
    // This method intentionally does not perform network calls in Phase 23.
  }
}
