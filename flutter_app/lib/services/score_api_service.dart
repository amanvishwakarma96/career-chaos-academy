import '../models/score_model.dart';
import 'api_client.dart';
import 'device_user_service.dart';

class ScoreApiService {
  ScoreApiService._();

  static final ScoreApiService instance = ScoreApiService._();

  Future<void> saveScore({
    required String roleId,
    required String chapterId,
    required ScoreModel score,
    int xp = 0,
  }) async {
    if (!ApiClient.instance.isEnabled) {
      return;
    }

    try {
      final userId = await DeviceUserService.instance.getOrCreateUserId();
      await ApiClient.instance.postMap(
        '/api/users/${Uri.encodeComponent(userId)}/scores',
        <String, dynamic>{
          'roleId': roleId,
          'chapterId': chapterId,
          ...score.toJson(),
          'xp': xp,
        },
      );
    } on Object {
      // Score API sync is optional; local progress remains safe.
    }
  }
}
