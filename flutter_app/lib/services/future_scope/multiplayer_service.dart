import '../../models/future_scope/multiplayer_models.dart';
import 'feature_flag_service.dart';

class MultiplayerService {
  MultiplayerService._();

  static final MultiplayerService instance = MultiplayerService._();

  bool get isAvailable => FeatureFlagService.instance.isEnabled('team_simulation') || FeatureFlagService.instance.isEnabled('multiplayer_placeholder');

  MultiplayerPlaceholderModel createSoloPlaceholder() {
    return const MultiplayerPlaceholderModel();
  }

  Future<void> prepareFutureSession(MultiplayerPlaceholderModel session) async {
    // Phase 28 connects multiplayer through TeamSessionService and backend REST APIs.
    // This method remains as a compatibility bridge for older future-scope callers.
  }
}
