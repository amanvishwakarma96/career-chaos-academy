import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/future_scope/versioning_models.dart';

class ContentVersionService {
  ContentVersionService._();

  static final ContentVersionService instance = ContentVersionService._();

  ContentVersionModel? contentVersion;
  AssetVersionModel? assetVersion;

  Future<void> load() async {
    await Future.wait(<Future<void>>[
      _loadContentManifest(),
      _loadAssetManifest(),
    ]);
  }

  Future<void> _loadContentManifest() async {
    try {
      final raw = await rootBundle.loadString('assets/config/content_manifest.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        contentVersion = ContentVersionModel.fromJson(decoded);
      }
    } catch (_) {
      contentVersion = const ContentVersionModel(contentPackId: 'core_roles', version: '1.0.0');
    }
  }

  Future<void> _loadAssetManifest() async {
    try {
      final raw = await rootBundle.loadString('assets/config/asset_manifest_version.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        assetVersion = AssetVersionModel.fromJson(decoded);
      }
    } catch (_) {
      assetVersion = const AssetVersionModel(assetPackId: 'base_visuals', version: '1.0.0');
    }
  }
}
