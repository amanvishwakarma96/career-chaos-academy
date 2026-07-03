import 'package:shared_preferences/shared_preferences.dart';

class DeviceUserService {
  DeviceUserService._();

  static final DeviceUserService instance = DeviceUserService._();
  static const String _userIdKey = 'career_chaos_user_id_v1';

  Future<String> getOrCreateUserId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_userIdKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final generated = 'local_${DateTime.now().microsecondsSinceEpoch}';
    await preferences.setString(_userIdKey, generated);
    return generated;
  }
}
