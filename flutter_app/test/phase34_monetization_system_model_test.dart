import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/product_model.dart';

void main() {
  test('Phase 34 product, entitlement, preview, and placeholder models parse correctly', () {
    final catalog = ProductCatalogModel.fromJson(<String, dynamic>{
      'version': 1,
      'monetization': <String, dynamic>{
        'enabled': true,
        'developmentMode': <String, dynamic>{
          'noPaymentRequired': true,
          'paymentProvider': 'placeholder_only',
        },
        'featureFlag': 'monetization_system',
      },
      'products': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'free_starter_role_pack',
          'title': 'Starter Role Pack',
          'productType': 'scenario_pack',
          'priceType': 'free',
          'amountMinor': 0,
          'entitlementKey': 'content.free.starter',
          'contentIds': <String>['core_roles_v23'],
        },
        <String, dynamic>{
          'id': 'premium_scenario_pack_bundle_v1',
          'title': 'Premium Scenario Pack Bundle',
          'productType': 'scenario_pack',
          'priceType': 'premium',
          'currency': 'INR',
          'amountMinor': 49900,
          'entitlementKey': 'content.premium.scenario_packs',
          'contentIds': <String>['developer_premium_pack_v1'],
          'scenarioPackIds': <String>['developer_premium_pack_v1'],
          'preview': <String, dynamic>{
            'title': 'Premium pack preview',
            'includedItems': <String>['Advanced role crisis pack'],
          },
        },
      ],
    });

    expect(catalog.monetization.enabled, isTrue);
    expect(catalog.monetization.noPaymentRequiredInDevelopment, isTrue);
    expect(catalog.products.length, 2);
    expect(catalog.products.first.isFree, isTrue);

    final premium = catalog.findProduct(contentId: 'developer_premium_pack_v1');
    expect(premium, isNotNull);
    expect(premium!.isPremium, isTrue);
    expect(premium.displayPrice, 'INR 499.00');
    expect(premium.preview['title'], 'Premium pack preview');

    final lockedCheck = EntitlementCheckModel.fromJson(<String, dynamic>{
      'userId': 'user-1',
      'allowed': false,
      'locked': true,
      'reason': 'premium_content_locked',
      'product': premium.toJson(),
      'preview': premium.preview,
    });
    expect(lockedCheck.locked, isTrue);
    expect(lockedCheck.product?.id, 'premium_scenario_pack_bundle_v1');

    final entitlement = EntitlementModel.fromJson(<String, dynamic>{
      'id': 'entitlement-1',
      'userId': 'user-1',
      'productId': 'premium_scenario_pack_bundle_v1',
      'entitlementKey': 'content.premium.scenario_packs',
      'contentIds': <String>['developer_premium_pack_v1'],
      'scenarioPackIds': <String>['developer_premium_pack_v1'],
      'active': true,
      'source': 'development_placeholder',
    });
    expect(entitlement.isActive, isTrue);
    expect(entitlement.matchesContent(contentId: 'developer_premium_pack_v1'), isTrue);

    final purchase = PurchasePlaceholderResultModel.fromJson(<String, dynamic>{
      'userId': 'user-1',
      'product': premium.toJson(),
      'status': 'development_entitlement_granted',
      'purchaseType': 'purchase_placeholder',
      'paymentRequired': false,
      'entitlement': entitlement.toJson(),
      'message': 'Development mode uses a placeholder purchase; no payment was required.',
      'monetization': <String, dynamic>{
        'enabled': true,
        'developmentMode': <String, dynamic>{'noPaymentRequired': true},
      },
    });
    expect(purchase.paymentRequired, isFalse);
    expect(purchase.entitlement?.matchesContent(productId: premium.id), isTrue);
  });
}
