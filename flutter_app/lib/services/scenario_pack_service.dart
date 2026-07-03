import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_metadata.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_pack_model.dart';
import 'api_client.dart';
import 'future_scope/feature_flag_service.dart';
import 'monetization_service.dart';

class ScenarioPackService {
  ScenarioPackService._();

  static final ScenarioPackService instance = ScenarioPackService._();
  static const String _assetPath = 'assets/game/scenario_packs/scenario_packs.json';
  static const String _cachedPackKey = 'career_chaos_cached_scenario_packs_v1';

  Future<ScenarioPackCatalogModel> loadCatalog({bool preferApi = true}) async {
    if (preferApi && ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/scenario-packs');
        return ScenarioPackCatalogModel.fromJson(json);
      } on Object {
        // Keep marketplace local-first and fail-safe.
      }
    }
    return _loadBundledCatalog();
  }

  Future<ScenarioPackCatalogModel> _loadBundledCatalog() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return ScenarioPackCatalogModel.fromJson(decoded);
    }
    return const ScenarioPackCatalogModel();
  }

  Future<List<ScenarioPackModel>> loadPublishedPacks({bool preferApi = true}) async {
    final catalog = await loadCatalog(preferApi: preferApi);
    return catalog.packs
        .where((pack) => isPlayable(pack))
        .toList(growable: false);
  }

  bool isPlayable(ScenarioPackModel pack) {
    if (!pack.isPublished || !pack.isApproved || pack.chapterCount == 0) return false;
    return pack.isCompatibleWithApp(
      appVersion: AppMetadata.versionName,
      featureEnabled: FeatureFlagService.instance.isEnabled,
    );
  }

  Future<List<RoleScenarioModel>> loadPublishedRoleScenarios({bool preferApi = true}) async {
    final packs = await loadPublishedPacks(preferApi: preferApi);
    final cached = await loadCachedPacks();
    final all = <String, ScenarioPackModel>{};
    for (final pack in packs) {
      if (await isAccessibleForPlay(pack)) all[pack.id] = pack;
    }
    for (final pack in cached) {
      if (isPlayable(pack) && await isAccessibleForPlay(pack)) all[pack.id] = pack;
    }
    return all.values.map((pack) => pack.toRoleScenario()).toList(growable: false);
  }

  Future<bool> isAccessibleForPlay(ScenarioPackModel pack) async {
    if (pack.isFree) return true;
    final check = await MonetizationService.instance.checkPackAccess(
      packId: pack.id,
      priceType: pack.priceType,
      roleId: pack.roleId,
    );
    return check.allowed;
  }

  Future<void> cachePackForOffline(ScenarioPackModel pack) async {
    if (!pack.isDownloadable || !pack.supportsOfflineCache) return;
    if (!await isAccessibleForPlay(pack)) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_cachedPackKey) ?? const <String>[];
    final encoded = jsonEncode(pack.toJson());
    final next = <String>[
      encoded,
      ...current.where((item) {
        try {
          final decoded = jsonDecode(item);
          return decoded is! Map || decoded['id'] != pack.id;
        } on Object {
          return false;
        }
      }),
    ];
    await prefs.setStringList(_cachedPackKey, next.take(25).toList(growable: false));
  }

  Future<List<ScenarioPackModel>> loadCachedPacks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_cachedPackKey) ?? const <String>[];
    final packs = <ScenarioPackModel>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          packs.add(ScenarioPackModel.fromJson(decoded));
        }
      } on Object {
        // Ignore corrupt cached packs.
      }
    }
    return packs;
  }

  Future<bool> isCached(String packId) async {
    final packs = await loadCachedPacks();
    return packs.any((pack) => pack.id == packId);
  }
}
