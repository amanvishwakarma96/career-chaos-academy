class ProductModel {
  final String id;
  final String title;
  final String description;
  final String productType;
  final String priceType;
  final String currency;
  final int amountMinor;
  final String billingPeriod;
  final bool isActive;
  final String featureFlag;
  final String entitlementKey;
  final List<String> contentIds;
  final List<String> scenarioPackIds;
  final List<String> roleIds;
  final Map<String, dynamic> preview;
  final bool developmentModeNoPaymentRequired;

  const ProductModel({
    required this.id,
    required this.title,
    this.description = '',
    this.productType = 'feature_unlock',
    this.priceType = 'free',
    this.currency = 'INR',
    this.amountMinor = 0,
    this.billingPeriod = '',
    this.isActive = true,
    this.featureFlag = 'monetization_system',
    this.entitlementKey = '',
    this.contentIds = const <String>[],
    this.scenarioPackIds = const <String>[],
    this.roleIds = const <String>[],
    this.preview = const <String, dynamic>{},
    this.developmentModeNoPaymentRequired = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = _string(json['id']);
    return ProductModel(
      id: id,
      title: _string(json['title'], fallback: 'Untitled Product'),
      description: _string(json['description']),
      productType: _normalizeProductType(json['productType'] ?? json['type']),
      priceType: _normalizePriceType(json['priceType']),
      currency: _string(json['currency'], fallback: 'INR'),
      amountMinor: _int(json['amountMinor'] ?? json['priceMinor']),
      billingPeriod: _string(json['billingPeriod']),
      isActive: json['isActive'] != false,
      featureFlag: _string(json['featureFlag'], fallback: 'monetization_system'),
      entitlementKey: _string(json['entitlementKey'], fallback: id.isEmpty ? '' : 'entitlement.$id'),
      contentIds: _stringList(json['contentIds']),
      scenarioPackIds: _stringList(json['scenarioPackIds']),
      roleIds: _stringList(json['roleIds']),
      preview: _stringKeyMap(json['preview']),
      developmentModeNoPaymentRequired: json['developmentModeNoPaymentRequired'] != false,
    );
  }

  bool get isFree => priceType == 'free';
  bool get isPremium => !isFree;
  bool get isSubscription => productType == 'subscription' || priceType == 'subscription';
  bool get isCertificatePayment => productType == 'certificate';
  bool get isCorporateLicense => productType == 'corporate_license';

  String get displayPrice {
    if (isFree || amountMinor <= 0) return 'Free';
    final amount = (amountMinor / 100).toStringAsFixed(2);
    final suffix = billingPeriod.isEmpty ? '' : ' / $billingPeriod';
    return '$currency $amount$suffix';
  }

  bool matchesContent({String contentId = '', String productId = '', String entitlementKey = '', String roleId = ''}) {
    if (productId.isNotEmpty && id == productId) return true;
    if (entitlementKey.isNotEmpty && this.entitlementKey == entitlementKey) return true;
    if (contentId.isNotEmpty && contentIds.contains(contentId)) return true;
    if (contentId.isNotEmpty && scenarioPackIds.contains(contentId)) return true;
    if (roleId.isNotEmpty && roleIds.contains(roleId) && isFree) return true;
    return false;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'productType': productType,
        'priceType': priceType,
        'currency': currency,
        'amountMinor': amountMinor,
        'billingPeriod': billingPeriod,
        'isActive': isActive,
        'featureFlag': featureFlag,
        'entitlementKey': entitlementKey,
        'contentIds': contentIds,
        'scenarioPackIds': scenarioPackIds,
        'roleIds': roleIds,
        'preview': preview,
        'developmentModeNoPaymentRequired': developmentModeNoPaymentRequired,
      };
}

class MonetizationFeatureStateModel {
  final bool enabled;
  final Map<String, dynamic> developmentMode;
  final String featureFlag;

  const MonetizationFeatureStateModel({
    this.enabled = false,
    this.developmentMode = const <String, dynamic>{},
    this.featureFlag = 'monetization_system',
  });

  factory MonetizationFeatureStateModel.fromJson(Map<String, dynamic> json) {
    return MonetizationFeatureStateModel(
      enabled: json['enabled'] == true,
      developmentMode: _stringKeyMap(json['developmentMode']),
      featureFlag: _string(json['featureFlag'], fallback: 'monetization_system'),
    );
  }

  bool get noPaymentRequiredInDevelopment => developmentMode['noPaymentRequired'] != false;
}

class ProductCatalogModel {
  final int version;
  final MonetizationFeatureStateModel monetization;
  final List<ProductModel> products;

  const ProductCatalogModel({
    this.version = 1,
    this.monetization = const MonetizationFeatureStateModel(),
    this.products = const <ProductModel>[],
  });

  factory ProductCatalogModel.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    return ProductCatalogModel(
      version: _int(json['version'], fallback: 1),
      monetization: json['monetization'] is Map<String, dynamic>
          ? MonetizationFeatureStateModel.fromJson(json['monetization'] as Map<String, dynamic>)
          : MonetizationFeatureStateModel(
              enabled: json['enabled'] == true,
              developmentMode: _stringKeyMap(json['developmentMode']),
            ),
      products: rawProducts is List
          ? rawProducts.whereType<Map<String, dynamic>>().map(ProductModel.fromJson).toList(growable: false)
          : const <ProductModel>[],
    );
  }

  ProductModel? findProduct({String contentId = '', String productId = '', String entitlementKey = '', String roleId = ''}) {
    for (final product in products) {
      if (product.matchesContent(
        contentId: contentId,
        productId: productId,
        entitlementKey: entitlementKey,
        roleId: roleId,
      )) {
        return product;
      }
    }
    return null;
  }
}

class EntitlementModel {
  final String id;
  final String userId;
  final String productId;
  final String entitlementKey;
  final List<String> contentIds;
  final List<String> scenarioPackIds;
  final String source;
  final bool active;
  final String grantedAt;
  final String expiresAt;
  final String verificationNote;

  const EntitlementModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.entitlementKey,
    this.contentIds = const <String>[],
    this.scenarioPackIds = const <String>[],
    this.source = 'development_placeholder',
    this.active = true,
    this.grantedAt = '',
    this.expiresAt = '',
    this.verificationNote = '',
  });

  factory EntitlementModel.fromJson(Map<String, dynamic> json) {
    return EntitlementModel(
      id: _string(json['id'], fallback: 'entitlement_${DateTime.now().microsecondsSinceEpoch}'),
      userId: _string(json['userId'], fallback: 'local_user'),
      productId: _string(json['productId']),
      entitlementKey: _string(json['entitlementKey']),
      contentIds: _stringList(json['contentIds']),
      scenarioPackIds: _stringList(json['scenarioPackIds']),
      source: _string(json['source'], fallback: 'development_placeholder'),
      active: json['active'] != false,
      grantedAt: _string(json['grantedAt']),
      expiresAt: _string(json['expiresAt']),
      verificationNote: _string(json['verificationNote']),
    );
  }

  bool get isActive {
    if (!active) return false;
    if (expiresAt.isEmpty) return true;
    final expiry = DateTime.tryParse(expiresAt);
    return expiry != null && expiry.isAfter(DateTime.now());
  }

  bool matchesContent({String contentId = '', String productId = '', String entitlementKey = ''}) {
    if (productId.isNotEmpty && this.productId == productId) return true;
    if (entitlementKey.isNotEmpty && this.entitlementKey == entitlementKey) return true;
    if (contentId.isNotEmpty && contentIds.contains(contentId)) return true;
    if (contentId.isNotEmpty && scenarioPackIds.contains(contentId)) return true;
    return false;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'productId': productId,
        'entitlementKey': entitlementKey,
        'contentIds': contentIds,
        'scenarioPackIds': scenarioPackIds,
        'source': source,
        'active': active,
        'grantedAt': grantedAt,
        'expiresAt': expiresAt,
        'verificationNote': verificationNote,
      };
}

class EntitlementCheckModel {
  final String userId;
  final bool allowed;
  final bool locked;
  final String reason;
  final ProductModel? product;
  final EntitlementModel? entitlement;
  final MonetizationFeatureStateModel monetization;
  final Map<String, dynamic> preview;

  const EntitlementCheckModel({
    required this.userId,
    required this.allowed,
    required this.locked,
    required this.reason,
    this.product,
    this.entitlement,
    this.monetization = const MonetizationFeatureStateModel(),
    this.preview = const <String, dynamic>{},
  });

  factory EntitlementCheckModel.fromJson(Map<String, dynamic> json) {
    return EntitlementCheckModel(
      userId: _string(json['userId'], fallback: 'local_user'),
      allowed: json['allowed'] == true,
      locked: json['locked'] == true,
      reason: _string(json['reason']),
      product: json['product'] is Map<String, dynamic> ? ProductModel.fromJson(json['product'] as Map<String, dynamic>) : null,
      entitlement: json['entitlement'] is Map<String, dynamic> ? EntitlementModel.fromJson(json['entitlement'] as Map<String, dynamic>) : null,
      monetization: json['monetization'] is Map<String, dynamic>
          ? MonetizationFeatureStateModel.fromJson(json['monetization'] as Map<String, dynamic>)
          : const MonetizationFeatureStateModel(),
      preview: _stringKeyMap(json['preview']),
    );
  }

  static const allowedFree = EntitlementCheckModel(
    userId: 'local_user',
    allowed: true,
    locked: false,
    reason: 'free_content',
  );
}

class PurchasePlaceholderResultModel {
  final String userId;
  final ProductModel? product;
  final String status;
  final String purchaseType;
  final bool paymentRequired;
  final EntitlementModel? entitlement;
  final String message;
  final MonetizationFeatureStateModel monetization;

  const PurchasePlaceholderResultModel({
    required this.userId,
    this.product,
    required this.status,
    required this.purchaseType,
    required this.paymentRequired,
    this.entitlement,
    this.message = '',
    this.monetization = const MonetizationFeatureStateModel(),
  });

  factory PurchasePlaceholderResultModel.fromJson(Map<String, dynamic> json) {
    return PurchasePlaceholderResultModel(
      userId: _string(json['userId'], fallback: 'local_user'),
      product: json['product'] is Map<String, dynamic> ? ProductModel.fromJson(json['product'] as Map<String, dynamic>) : null,
      status: _string(json['status'], fallback: 'placeholder'),
      purchaseType: _string(json['purchaseType'], fallback: 'purchase_placeholder'),
      paymentRequired: json['paymentRequired'] == true,
      entitlement: json['entitlement'] is Map<String, dynamic> ? EntitlementModel.fromJson(json['entitlement'] as Map<String, dynamic>) : null,
      message: _string(json['message']),
      monetization: json['monetization'] is Map<String, dynamic>
          ? MonetizationFeatureStateModel.fromJson(json['monetization'] as Map<String, dynamic>)
          : const MonetizationFeatureStateModel(),
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList(growable: false);
}

Map<String, dynamic> _stringKeyMap(Object? value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String _normalizeProductType(Object? value) {
  final raw = value is String ? value.trim().toLowerCase() : '';
  switch (raw) {
    case 'scenario_pack':
    case 'subscription':
    case 'certificate':
    case 'corporate_license':
    case 'feature_unlock':
      return raw;
    default:
      return 'feature_unlock';
  }
}

String _normalizePriceType(Object? value) {
  final raw = value is String ? value.trim().toLowerCase() : '';
  switch (raw) {
    case 'premium':
    case 'subscription':
    case 'payment_placeholder':
    case 'license_placeholder':
      return raw;
    default:
      return 'free';
  }
}
