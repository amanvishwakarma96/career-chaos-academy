import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';
import 'api_client.dart';
import 'device_user_service.dart';
import 'future_scope/feature_flag_service.dart';

class MonetizationService {
  MonetizationService._();

  static final MonetizationService instance = MonetizationService._();
  static const String _assetPath = 'assets/game/monetization/products.json';
  static const String _entitlementsKey = 'career_chaos_monetization_entitlements_v1';

  bool get isEnabled => FeatureFlagService.instance.isEnabled('monetization_system');

  Future<ProductCatalogModel> loadCatalog({bool preferApi = true}) async {
    if (preferApi && ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/monetization/products');
        return ProductCatalogModel.fromJson(json);
      } on Object {
        // Use bundled purchase-ready architecture when backend is not configured.
      }
    }
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    final map = decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
    return ProductCatalogModel.fromJson(<String, dynamic>{
      ...map,
      'monetization': <String, dynamic>{
        'enabled': isEnabled,
        'developmentMode': map['developmentMode'] ?? const <String, dynamic>{'noPaymentRequired': true},
        'featureFlag': 'monetization_system',
      },
    });
  }

  Future<List<EntitlementModel>> loadEntitlements({bool preferApi = true}) async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    if (preferApi && ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/users/${Uri.encodeComponent(userId)}/entitlements');
        final raw = json['activeEntitlements'] ?? json['entitlements'];
        if (raw is List) {
          return raw.whereType<Map<String, dynamic>>().map(EntitlementModel.fromJson).where((item) => item.isActive).toList(growable: false);
        }
      } on Object {
        // Local fallback below.
      }
    }
    return _readLocalEntitlements();
  }

  Future<EntitlementCheckModel> checkEntitlement({
    String contentId = '',
    String productId = '',
    String entitlementKey = '',
    String roleId = '',
    String contentTier = 'free',
    bool preferApi = true,
  }) async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    if (!isEnabled) {
      return EntitlementCheckModel(
        userId: userId,
        allowed: true,
        locked: false,
        reason: 'monetization_disabled_by_feature_flag',
      );
    }
    if (contentTier == 'free') {
      return EntitlementCheckModel(
        userId: userId,
        allowed: true,
        locked: false,
        reason: 'free_content',
      );
    }
    if (preferApi && ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap(
          '/api/users/${Uri.encodeComponent(userId)}/entitlements/check',
          <String, dynamic>{
            'contentId': contentId,
            'productId': productId,
            'entitlementKey': entitlementKey,
            'roleId': roleId,
            'contentTier': contentTier,
          },
        );
        return EntitlementCheckModel.fromJson(json);
      } on Object {
        // Local fallback below.
      }
    }
    final catalog = await loadCatalog(preferApi: false);
    final product = catalog.findProduct(
      contentId: contentId,
      productId: productId,
      entitlementKey: entitlementKey,
      roleId: roleId,
    );
    if (product?.isFree == true) {
      return EntitlementCheckModel(
        userId: userId,
        allowed: true,
        locked: false,
        reason: 'free_content',
        product: product,
        monetization: catalog.monetization,
      );
    }
    final entitlements = await _readLocalEntitlements();
    EntitlementModel? entitlement;
    for (final item in entitlements.where((item) => item.isActive)) {
      if (item.matchesContent(
        contentId: contentId,
        productId: product?.id ?? productId,
        entitlementKey: product?.entitlementKey ?? entitlementKey,
      )) {
        entitlement = item;
        break;
      }
    }
    return EntitlementCheckModel(
      userId: userId,
      allowed: entitlement != null,
      locked: entitlement == null,
      reason: entitlement != null ? 'active_entitlement_found' : 'premium_content_locked',
      product: product,
      entitlement: entitlement,
      monetization: catalog.monetization,
      preview: product?.preview ?? const <String, dynamic>{},
    );
  }

  Future<EntitlementCheckModel> checkPackAccess({
    required String packId,
    required String priceType,
    String roleId = '',
  }) {
    return checkEntitlement(
      contentId: packId,
      roleId: roleId,
      contentTier: priceType,
    );
  }

  Future<Map<String, dynamic>> loadPremiumPreview(String productId, {bool preferApi = true}) async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    if (preferApi && ApiClient.instance.isEnabled) {
      try {
        return ApiClient.instance.getMap('/api/monetization/premium-preview/${Uri.encodeComponent(productId)}?userId=${Uri.encodeComponent(userId)}');
      } on Object {
        // Local fallback below.
      }
    }
    final catalog = await loadCatalog(preferApi: false);
    final product = catalog.findProduct(productId: productId);
    if (product == null) {
      return <String, dynamic>{
        'locked': true,
        'allowed': false,
        'reason': 'product_not_found',
        'preview': const <String, dynamic>{},
      };
    }
    final check = await checkEntitlement(productId: product.id, contentTier: product.priceType, preferApi: false);
    return <String, dynamic>{
      'product': product.toJson(),
      'preview': product.preview,
      'locked': check.locked,
      'allowed': check.allowed,
      'reason': check.reason,
    };
  }

  Future<PurchasePlaceholderResultModel> purchasePlaceholder(String productId, {bool preferApi = true}) {
    return _placeholder('/purchases/placeholder', productId, preferApi: preferApi);
  }

  Future<PurchasePlaceholderResultModel> subscriptionPlaceholder(String productId, {bool preferApi = true}) {
    return _placeholder('/subscriptions/placeholder', productId, preferApi: preferApi);
  }

  Future<PurchasePlaceholderResultModel> certificatePaymentPlaceholder(String productId, {bool preferApi = true}) {
    return _placeholder('/certificates/payment-placeholder', productId, preferApi: preferApi);
  }

  Future<PurchasePlaceholderResultModel> corporateLicensePlaceholder(String productId, {bool preferApi = true}) {
    return _placeholder('/corporate-license/placeholder', productId, preferApi: preferApi);
  }

  Future<PurchasePlaceholderResultModel> _placeholder(String suffix, String productId, {bool preferApi = true}) async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    if (preferApi && ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap(
          '/api/users/${Uri.encodeComponent(userId)}$suffix',
          <String, dynamic>{'productId': productId},
        );
        final result = PurchasePlaceholderResultModel.fromJson(json);
        if (result.entitlement != null) await _upsertLocalEntitlement(result.entitlement!);
        return result;
      } on Object {
        // Local placeholder fallback below.
      }
    }
    final catalog = await loadCatalog(preferApi: false);
    final product = catalog.findProduct(productId: productId);
    if (product == null) {
      return PurchasePlaceholderResultModel(
        userId: userId,
        status: 'product_not_found',
        purchaseType: suffix.replaceAll('/', '_'),
        paymentRequired: false,
        message: 'Product not found in bundled catalog.',
        monetization: catalog.monetization,
      );
    }
    if (!isEnabled) {
      return PurchasePlaceholderResultModel(
        userId: userId,
        product: product,
        status: 'not_required',
        purchaseType: suffix.replaceAll('/', '_'),
        paymentRequired: false,
        message: 'Monetization is disabled by feature flag.',
        monetization: catalog.monetization,
      );
    }
    if (product.isFree) {
      return PurchasePlaceholderResultModel(
        userId: userId,
        product: product,
        status: 'free_content',
        purchaseType: suffix.replaceAll('/', '_'),
        paymentRequired: false,
        message: 'Free product does not require purchase.',
        monetization: catalog.monetization,
      );
    }
    final entitlement = EntitlementModel(
      id: 'entitlement_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      productId: product.id,
      entitlementKey: product.entitlementKey,
      contentIds: product.contentIds,
      scenarioPackIds: product.scenarioPackIds,
      source: 'development_placeholder',
      active: true,
      grantedAt: DateTime.now().toIso8601String(),
      verificationNote: 'Local development placeholder; replace with receipt validation before production.',
    );
    await _upsertLocalEntitlement(entitlement);
    return PurchasePlaceholderResultModel(
      userId: userId,
      product: product,
      status: 'development_entitlement_granted',
      purchaseType: suffix.replaceAll('/', '_'),
      paymentRequired: false,
      entitlement: entitlement,
      message: 'Development placeholder granted entitlement. No payment was required.',
      monetization: catalog.monetization,
    );
  }

  Future<List<EntitlementModel>> restorePurchasesPlaceholder({bool preferApi = true}) async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    if (preferApi && ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/users/${Uri.encodeComponent(userId)}/purchases/restore', const <String, dynamic>{});
        final raw = json['entitlements'];
        if (raw is List) {
          final items = raw.whereType<Map<String, dynamic>>().map(EntitlementModel.fromJson).toList(growable: false);
          for (final item in items) {
            await _upsertLocalEntitlement(item);
          }
          return items;
        }
      } on Object {
        // Local restore fallback below.
      }
    }
    return _readLocalEntitlements();
  }

  Future<List<EntitlementModel>> _readLocalEntitlements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_entitlementsKey) ?? const <String>[];
    final entitlements = <EntitlementModel>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          entitlements.add(EntitlementModel.fromJson(decoded));
        }
      } on Object {
        // Ignore corrupted entitlement placeholders.
      }
    }
    return entitlements.where((item) => item.isActive).toList(growable: false);
  }

  Future<void> _upsertLocalEntitlement(EntitlementModel entitlement) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _readLocalEntitlements();
    final next = <EntitlementModel>[
      entitlement,
      ...current.where((item) => item.productId != entitlement.productId || item.entitlementKey != entitlement.entitlementKey),
    ];
    await prefs.setStringList(
      _entitlementsKey,
      next.take(100).map((item) => jsonEncode(item.toJson())).toList(growable: false),
    );
  }
}
