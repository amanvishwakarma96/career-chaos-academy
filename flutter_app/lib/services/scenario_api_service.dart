import '../models/role_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import 'api_client.dart';

class ScenarioApiService {
  ScenarioApiService._();

  static final ScenarioApiService instance = ScenarioApiService._();

  Future<List<RoleScenarioModel>?> loadScenarios() async {
    if (!ApiClient.instance.isEnabled) {
      return null;
    }

    try {
      final roleItems = await ApiClient.instance.getList('/api/roles');
      final roles = <RoleScenarioModel>[];

      for (final item in roleItems) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final role = RoleModel.fromJson(item);
        final chapterItems = await ApiClient.instance.getList(
          '/api/roles/${Uri.encodeComponent(role.id)}/chapters',
        );
        final chapters = <ScenarioModel>[];

        for (final chapterItem in chapterItems) {
          if (chapterItem is! Map<String, dynamic>) {
            continue;
          }
          final chapterId = chapterItem['id'];
          if (chapterId is! String || chapterId.trim().isEmpty) {
            continue;
          }

          final scenarioJson = await ApiClient.instance.getMap(
            '/api/chapters/${Uri.encodeComponent(chapterId)}/scenario',
          );
          chapters.add(ScenarioModel.fromJson(scenarioJson, role: role));
        }

        if (chapters.isNotEmpty) {
          roles.add(RoleScenarioModel(role: role, chapters: chapters));
        }
      }

      return roles.isEmpty ? null : List<RoleScenarioModel>.unmodifiable(roles);
    } on Object {
      return null;
    }
  }
}
