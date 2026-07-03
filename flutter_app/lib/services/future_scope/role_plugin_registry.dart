import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/future_scope/role_plugin_model.dart';
import 'feature_flag_service.dart';

class RolePluginRegistry {
  RolePluginRegistry._();

  static final RolePluginRegistry instance = RolePluginRegistry._();

  List<RolePluginModel> _plugins = const <RolePluginModel>[];

  List<RolePluginModel> get plugins => _plugins;

  Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/config/role_plugins.json');
      final decoded = jsonDecode(raw);
      final items = decoded is Map<String, dynamic> ? decoded['plugins'] : null;
      if (items is List) {
        _plugins = items
            .whereType<Map<String, dynamic>>()
            .map(RolePluginModel.fromJson)
            .where((plugin) => plugin.pluginId.isNotEmpty && plugin.roleId.isNotEmpty)
            .toList(growable: false);
      }
    } catch (_) {
      _plugins = const <RolePluginModel>[];
    }
  }

  RolePluginModel? pluginForRole(String roleId) {
    for (final plugin in _plugins) {
      if (plugin.roleId == roleId && _isPluginEnabled(plugin)) return plugin;
    }
    return null;
  }

  bool _isPluginEnabled(RolePluginModel plugin) {
    if (!plugin.enabled) return false;
    for (final flag in plugin.requiredFeatureFlags) {
      if (!FeatureFlagService.instance.isEnabled(flag)) return false;
    }
    return true;
  }
}
