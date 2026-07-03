import '../models/progress_snapshot_model.dart';
import 'api_client.dart';
import 'device_user_service.dart';

class ProgressApiService {
  ProgressApiService._();

  static final ProgressApiService instance = ProgressApiService._();

  Future<ProgressSnapshotModel?> loadProgress() async {
    if (!ApiClient.instance.isEnabled) {
      return null;
    }

    try {
      final userId = await DeviceUserService.instance.getOrCreateUserId();
      final response = await ApiClient.instance.getMap(
        '/api/users/${Uri.encodeComponent(userId)}/progress',
      );
      final progress = response['progress'];
      if (progress is Map<String, dynamic>) {
        return ProgressSnapshotModel.fromJson(progress);
      }
    } on Object {
      return null;
    }

    return null;
  }

  Future<void> saveProgress(ProgressSnapshotModel snapshot) async {
    if (!ApiClient.instance.isEnabled) {
      return;
    }

    try {
      final userId = await DeviceUserService.instance.getOrCreateUserId();
      await ApiClient.instance.postMap(
        '/api/users/${Uri.encodeComponent(userId)}/progress',
        <String, dynamic>{'progress': snapshot.toJson()},
      );
    } on Object {
      // API sync is optional. Local storage remains the source of continuity
      // when the backend is offline or not configured.
    }
  }
}
