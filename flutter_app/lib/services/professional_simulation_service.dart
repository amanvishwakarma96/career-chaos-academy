import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/professional/role_skill_map_model.dart';
import '../models/scenario_model.dart';

class ProfessionalSimulationService {
  ProfessionalSimulationService._();

  static final ProfessionalSimulationService instance =
      ProfessionalSimulationService._();

  static const String defaultAssetPath =
      'assets/game/professional/role_skill_maps.json';

  Map<String, RoleSkillMapModel>? _cache;

  Future<Map<String, RoleSkillMapModel>> loadSkillMaps({
    String assetPath = defaultAssetPath,
  }) async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }

    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('role_skill_maps root must be an object.');
    }
    final roles = decoded['roles'];
    if (roles is! List) {
      throw const FormatException('role_skill_maps.roles must be a list.');
    }
    final result = <String, RoleSkillMapModel>{};
    for (final item in roles.whereType<Map<String, dynamic>>()) {
      final map = RoleSkillMapModel.fromJson(item);
      if (map.roleId.isNotEmpty) {
        result[map.roleId] = map;
      }
    }
    _cache = Map<String, RoleSkillMapModel>.unmodifiable(result);
    return _cache!;
  }

  Future<RoleSkillMapModel?> skillMapForRole(String roleId) async {
    final maps = await loadSkillMaps();
    return maps[roleId];
  }

  String mentorFeedbackForChoice({
    required ScenarioModel scenario,
    required String outcomeFeedback,
  }) {
    if (outcomeFeedback.trim().isNotEmpty) {
      return outcomeFeedback.trim();
    }
    if (scenario.mentorFeedback.trim().isNotEmpty) {
      return scenario.mentorFeedback.trim();
    }
    if (scenario.skillLevel == 'advanced') {
      return 'Mentor note: advanced work is less about being fast and more about making risk visible before it becomes expensive.';
    }
    return 'Mentor note: explain your reasoning, document what you checked, and escalate uncertainty early.';
  }

  String safeExplanationForScenario(ScenarioModel scenario) {
    if (scenario.safeExplanation.trim().isNotEmpty) {
      return scenario.safeExplanation.trim();
    }
    if (scenario.safetyDisclaimer?.trim().isNotEmpty == true) {
      return scenario.safetyDisclaimer!.trim();
    }
    if (scenario.safetyGuardrails.isNotEmpty) {
      return scenario.safetyGuardrails.join('\n');
    }
    return 'Professional safety note: this is a learning simulation. In real work, follow your organization\'s approved process, document evidence, and escalate high-risk decisions.';
  }

  List<String> missingChapterLearningFields(Iterable<ScenarioModel> chapters) {
    final missing = <String>[];
    for (final chapter in chapters) {
      if (chapter.learningObjective.isEmpty) {
        missing.add('${chapter.id}: learningObjective');
      }
      if (chapter.practicalTakeaway.isEmpty) {
        missing.add('${chapter.id}: practicalTakeaway');
      }
    }
    return missing;
  }
}
