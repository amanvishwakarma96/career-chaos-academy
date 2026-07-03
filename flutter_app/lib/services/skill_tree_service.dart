
import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/mini_game_model.dart';
import '../models/progress_snapshot_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../models/skill_tree/skill_tree_model.dart';

class SkillTreeService {
  SkillTreeService._();

  static final SkillTreeService instance = SkillTreeService._();
  static const _assetPath = 'assets/game/skill_trees/skill_trees.json';

  List<SkillTreeModel>? _cachedTrees;

  Future<List<SkillTreeModel>> loadSkillTrees() async {
    if (_cachedTrees != null) return _cachedTrees!;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw);
      final list = decoded is Map<String, dynamic> ? decoded['skillTrees'] : null;
      if (list is List) {
        _cachedTrees = list
            .whereType<Map<String, dynamic>>()
            .map(SkillTreeModel.fromJson)
            .where((tree) => tree.roleId.isNotEmpty && tree.nodes.isNotEmpty)
            .toList(growable: false);
      }
    } on Object {
      _cachedTrees = const <SkillTreeModel>[];
    }
    _cachedTrees ??= const <SkillTreeModel>[];
    return _cachedTrees!;
  }

  Future<SkillTreeModel?> skillTreeForRole(String roleId) async {
    final trees = await loadSkillTrees();
    for (final tree in trees) {
      if (tree.roleId == roleId) return tree;
    }
    return null;
  }

  SkillTreeProgressModel progressForRole({
    required ProgressSnapshotModel snapshot,
    required String roleId,
  }) {
    return snapshot.skillTreeProgressByRole[roleId] ?? SkillTreeProgressModel(roleId: roleId);
  }

  Future<Map<String, SkillTreeProgressModel>> awardChapterProgress({
    required Map<String, SkillTreeProgressModel> current,
    required RoleScenarioModel roleScenario,
    required ScenarioModel chapter,
    int points = 25,
  }) async {
    final tree = await skillTreeForRole(roleScenario.role.id);
    if (tree == null) return current;
    return _award(
      current: current,
      tree: tree,
      roleId: roleScenario.role.id,
      skillNodeIds: _nodeIdsForChapter(tree, chapter),
      sourceId: 'chapter:${chapter.id}',
      points: points,
    );
  }

  Future<Map<String, SkillTreeProgressModel>> awardMiniGameProgress({
    required Map<String, SkillTreeProgressModel> current,
    required RoleScenarioModel roleScenario,
    required ScenarioModel chapter,
    required MiniGameModel miniGame,
    required bool isSuccess,
  }) async {
    final tree = await skillTreeForRole(roleScenario.role.id);
    if (tree == null) return current;
    final nodeIds = miniGame.skillNodeIds.isNotEmpty
        ? miniGame.skillNodeIds
        : _nodeIdsForChapter(tree, chapter);
    return _award(
      current: current,
      tree: tree,
      roleId: roleScenario.role.id,
      skillNodeIds: nodeIds,
      sourceId: 'miniGame:${miniGame.id}:${isSuccess ? 'success' : 'failure'}',
      points: isSuccess ? 20 : 8,
    );
  }

  Map<String, SkillTreeProgressModel> _award({
    required Map<String, SkillTreeProgressModel> current,
    required SkillTreeModel tree,
    required String roleId,
    required List<String> skillNodeIds,
    required String sourceId,
    required int points,
  }) {
    var roleProgress = current[roleId] ?? SkillTreeProgressModel(roleId: roleId);
    for (final nodeId in skillNodeIds) {
      final node = tree.nodeById(nodeId);
      if (node == null) continue;
      if (!roleProgress.isNodeUnlocked(node)) continue;
      final nextNodeProgress = roleProgress.progressFor(nodeId).addProgress(
            sourceId: sourceId,
            points: points,
            masteryTarget: node.masteryTarget,
          );
      roleProgress = roleProgress.upsertNodeProgress(nextNodeProgress);
    }
    final next = Map<String, SkillTreeProgressModel>.from(current)
      ..[roleId] = roleProgress;
    return Map<String, SkillTreeProgressModel>.unmodifiable(next);
  }

  List<String> _nodeIdsForChapter(SkillTreeModel tree, ScenarioModel chapter) {
    if (chapter.skillNodeIds.isNotEmpty) return chapter.skillNodeIds;
    final matches = tree.nodes
        .where((node) => node.linkedChapterIds.contains(chapter.id))
        .map((node) => node.id)
        .toList(growable: false);
    if (matches.isNotEmpty) return matches;
    if (tree.nodes.isEmpty) return const <String>[];
    return <String>[tree.nodes.first.id];
  }

  Future<List<SkillNodeModel>> weakUnlockedSkillNodes({
    required ProgressSnapshotModel snapshot,
    required String roleId,
    int limit = 3,
  }) async {
    final tree = await skillTreeForRole(roleId);
    if (tree == null) return const <SkillNodeModel>[];
    final progress = progressForRole(snapshot: snapshot, roleId: roleId);
    final nodes = tree.nodes.where(progress.isNodeUnlocked).toList(growable: true)
      ..sort((a, b) {
        final aPercent = progress.progressFor(a.id).masteryPercent(masteryTarget: a.masteryTarget);
        final bPercent = progress.progressFor(b.id).masteryPercent(masteryTarget: b.masteryTarget);
        return aPercent.compareTo(bPercent);
      });
    return nodes.take(limit).toList(growable: false);
  }
}
