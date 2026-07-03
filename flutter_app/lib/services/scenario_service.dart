import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/json_reader.dart';
import '../data/scenario_asset_paths.dart';
import '../models/role_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../models/relationship_score_model.dart';
import '../models/role_progress_model.dart';
import '../models/score_model.dart';
import 'consequence_service.dart';
import 'scenario_api_service.dart';
import 'scenario_pack_service.dart';

class ScenarioLoadError {
  final String assetPath;
  final String message;

  const ScenarioLoadError({required this.assetPath, required this.message});
}

class ScenarioLoadResult {
  final List<RoleScenarioModel> roles;
  final List<ScenarioLoadError> errors;

  const ScenarioLoadResult({required this.roles, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
  bool get hasScenarios => roles.any((roleScenario) => roleScenario.hasChapters);

  List<ScenarioModel> get scenarios {
    return roles
        .expand((roleScenario) => roleScenario.chapters)
        .toList(growable: false);
  }
}

class ScenarioService {
  ScenarioService._();

  static final ScenarioService instance = ScenarioService._();

  Future<ScenarioLoadResult> loadScenarios({
    List<String> assetPaths = scenarioAssetPaths,
    bool preferApi = true,
  }) async {
    if (preferApi) {
      final apiRoles = await ScenarioApiService.instance.loadScenarios();
      if (apiRoles != null && apiRoles.isNotEmpty) {
        final packRoles = await ScenarioPackService.instance.loadPublishedRoleScenarios(preferApi: true);
        return ScenarioLoadResult(
          roles: List<RoleScenarioModel>.unmodifiable(_mergeRoleScenarios(apiRoles, packRoles)),
          errors: const <ScenarioLoadError>[],
        );
      }
    }

    final roles = <RoleScenarioModel>[];
    final errors = <ScenarioLoadError>[];

    for (final assetPath in assetPaths) {
      try {
        final roleScenario = await _loadScenarioFile(assetPath);
        if (roleScenario.hasChapters) {
          roles.add(roleScenario);
        }
      } on Object catch (error) {
        errors.add(
          ScenarioLoadError(
            assetPath: assetPath,
            message: _friendlyErrorMessage(error),
          ),
        );
      }
    }

    final packRoles = await ScenarioPackService.instance.loadPublishedRoleScenarios(preferApi: false);

    return ScenarioLoadResult(
      roles: List<RoleScenarioModel>.unmodifiable(_mergeRoleScenarios(roles, packRoles)),
      errors: List<ScenarioLoadError>.unmodifiable(errors),
    );
  }


  List<RoleScenarioModel> _mergeRoleScenarios(
    List<RoleScenarioModel> baseRoles,
    List<RoleScenarioModel> packRoles,
  ) {
    final byRole = <String, RoleScenarioModel>{
      for (final roleScenario in baseRoles) roleScenario.role.id: roleScenario,
    };
    for (final packRole in packRoles) {
      final existing = byRole[packRole.role.id];
      if (existing == null) {
        byRole[packRole.role.id] = packRole;
      } else {
        final existingIds = existing.chapters.map((chapter) => chapter.id).toSet();
        final newChapters = packRole.chapters
            .where((chapter) => !existingIds.contains(chapter.id))
            .toList(growable: false);
        byRole[packRole.role.id] = RoleScenarioModel(
          role: existing.role,
          chapters: <ScenarioModel>[...existing.chapters, ...newChapters],
        );
      }
    }
    return byRole.values.toList(growable: false);
  }

  Future<RoleScenarioModel> _loadScenarioFile(String assetPath) async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Scenario file root must be an object.');
    }

    final role = RoleModel.fromJson(
      JsonReader.readMap(decoded, 'role', parent: assetPath),
    );
    final chapterItems = JsonReader.readList(
      decoded,
      'chapters',
      parent: assetPath,
    );

    final chapters = chapterItems.map((chapter) {
      if (chapter is! Map<String, dynamic>) {
        throw FormatException('$assetPath.chapters item must be an object.');
      }
      return ScenarioModel.fromJson(chapter, role: role);
    }).toList(growable: false);

    return RoleScenarioModel(role: role, chapters: chapters);
  }

  List<ScenarioModel> filterChaptersForProgress({
    required RoleScenarioModel roleScenario,
    required RoleProgressModel progress,
    required Set<String> activeFlags,
    required Set<String> unlockedCleanupMissionIds,
    Set<String> storyFlags = const <String>{},
    RelationshipScoreModel relationship = RelationshipScoreModel.zero,
  }) {
    return roleScenario.chapters.where((chapter) {
      final availability = ConsequenceService.instance.availabilityForChapter(
        chapter: chapter,
        activeFlags: activeFlags,
        completedChapterIds: progress.completedChapterIds,
        roleScore: progress.roleScore,
        unlockedCleanupMissionIds: unlockedCleanupMissionIds,
        storyFlags: storyFlags,
        relationship: relationship,
      );
      if (chapter.isCleanupMission) {
        return availability.isAvailable || unlockedCleanupMissionIds.contains(chapter.id);
      }
      return !availability.isBlocked;
    }).toList(growable: false);
  }

  ChapterAvailability chapterAvailability({
    required ScenarioModel chapter,
    required RoleProgressModel progress,
    required Set<String> activeFlags,
    required Set<String> unlockedCleanupMissionIds,
    ScoreModel? roleScore,
    Set<String> storyFlags = const <String>{},
    RelationshipScoreModel relationship = RelationshipScoreModel.zero,
  }) {
    return ConsequenceService.instance.availabilityForChapter(
      chapter: chapter,
      activeFlags: activeFlags,
      completedChapterIds: progress.completedChapterIds,
      roleScore: roleScore ?? progress.roleScore,
      unlockedCleanupMissionIds: unlockedCleanupMissionIds,
      storyFlags: storyFlags,
      relationship: relationship,
    );
  }

  String _friendlyErrorMessage(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    if (error is FlutterError) {
      return error.message;
    }
    return 'Unable to load this scenario file.';
  }
}
