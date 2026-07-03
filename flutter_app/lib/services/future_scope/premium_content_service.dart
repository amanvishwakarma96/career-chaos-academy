import '../../models/future_scope/access_models.dart';
import '../monetization_service.dart';
import 'feature_flag_service.dart';

class PremiumContentService {
  const PremiumContentService();

  bool canAccess(ContentAccessModel access, {bool userHasPremium = false}) {
    if (!FeatureFlagService.instance.isEnabled('monetization_system')) return true;
    switch (access.tier) {
      case ContentAccessTier.free:
        return true;
      case ContentAccessTier.premium:
        return userHasPremium;
      case ContentAccessTier.creatorOnly:
        return FeatureFlagService.instance.isEnabled('creator_mode');
    }
  }

  Future<bool> canAccessAsync(
    ContentAccessModel access, {
    String contentId = '',
    String productId = '',
    String roleId = '',
  }) async {
    if (!FeatureFlagService.instance.isEnabled('monetization_system')) return true;
    switch (access.tier) {
      case ContentAccessTier.free:
        return true;
      case ContentAccessTier.premium:
        final check = await MonetizationService.instance.checkEntitlement(
          contentId: contentId,
          productId: productId,
          roleId: roleId,
          contentTier: 'premium',
        );
        return check.allowed;
      case ContentAccessTier.creatorOnly:
        return FeatureFlagService.instance.isEnabled('creator_mode');
    }
  }
}
