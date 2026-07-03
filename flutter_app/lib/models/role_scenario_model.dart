import 'role_model.dart';
import 'scenario_model.dart';

class RoleScenarioModel {
  final RoleModel role;
  final List<ScenarioModel> chapters;

  const RoleScenarioModel({required this.role, required this.chapters});

  List<ScenarioModel> get mainChapters => chapters
      .where((chapter) => !chapter.isCleanupMission && !chapter.isFinale)
      .toList(growable: false);

  List<ScenarioModel> get cleanupMissions => chapters
      .where((chapter) => chapter.isCleanupMission)
      .toList(growable: false);

  List<ScenarioModel> get finaleChapters => chapters
      .where((chapter) => chapter.isFinale)
      .toList(growable: false);

  int get totalChapters => chapters.length;
  int get playableChapterCount => mainChapters.length + finaleChapters.length;
  bool get hasChapters => chapters.isNotEmpty;
}
