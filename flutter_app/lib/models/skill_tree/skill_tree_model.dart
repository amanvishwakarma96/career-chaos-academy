
class SkillNodeModel {
  final String id;
  final String title;
  final String description;
  final String level;
  final String category;
  final List<String> prerequisiteNodeIds;
  final List<String> linkedChapterIds;
  final List<String> linkedMiniGameIds;
  final int masteryTarget;
  final String unlocksBadgeId;

  const SkillNodeModel({
    required this.id,
    required this.title,
    this.description = '',
    this.level = 'beginner',
    this.category = 'general',
    this.prerequisiteNodeIds = const <String>[],
    this.linkedChapterIds = const <String>[],
    this.linkedMiniGameIds = const <String>[],
    this.masteryTarget = 100,
    this.unlocksBadgeId = '',
  });

  factory SkillNodeModel.fromJson(Map<String, dynamic> json) {
    return SkillNodeModel(
      id: _readString(json['id']),
      title: _readString(json['title']),
      description: _readString(json['description']),
      level: _readString(json['level']).isEmpty ? 'beginner' : _readString(json['level']),
      category: _readString(json['category']).isEmpty ? 'general' : _readString(json['category']),
      prerequisiteNodeIds: _readStringList(json['prerequisiteNodeIds']),
      linkedChapterIds: _readStringList(json['linkedChapterIds']),
      linkedMiniGameIds: _readStringList(json['linkedMiniGameIds']),
      masteryTarget: _readPositiveInt(json['masteryTarget'], fallback: 100),
      unlocksBadgeId: _readString(json['unlocksBadgeId']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'level': level,
        'category': category,
        'prerequisiteNodeIds': prerequisiteNodeIds,
        'linkedChapterIds': linkedChapterIds,
        'linkedMiniGameIds': linkedMiniGameIds,
        'masteryTarget': masteryTarget,
        'unlocksBadgeId': unlocksBadgeId,
      };
}

class SkillTreeModel {
  final String roleId;
  final String title;
  final String description;
  final String version;
  final List<SkillNodeModel> nodes;

  const SkillTreeModel({
    required this.roleId,
    required this.title,
    this.description = '',
    this.version = '1.0.0',
    this.nodes = const <SkillNodeModel>[],
  });

  factory SkillTreeModel.fromJson(Map<String, dynamic> json) {
    final nodeItems = json['nodes'];
    return SkillTreeModel(
      roleId: _readString(json['roleId']),
      title: _readString(json['title']),
      description: _readString(json['description']),
      version: _readString(json['version']).isEmpty ? '1.0.0' : _readString(json['version']),
      nodes: nodeItems is List
          ? nodeItems.whereType<Map<String, dynamic>>().map(SkillNodeModel.fromJson).where((node) => node.id.isNotEmpty).toList(growable: false)
          : const <SkillNodeModel>[],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roleId': roleId,
        'title': title,
        'description': description,
        'version': version,
        'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
      };

  SkillNodeModel? nodeById(String nodeId) {
    for (final node in nodes) {
      if (node.id == nodeId) return node;
    }
    return null;
  }
}

class SkillNodeProgressModel {
  final String nodeId;
  final int masteryPoints;
  final List<String> completedSourceIds;

  const SkillNodeProgressModel({
    required this.nodeId,
    this.masteryPoints = 0,
    this.completedSourceIds = const <String>[],
  });

  factory SkillNodeProgressModel.fromJson(Map<String, dynamic> json) {
    return SkillNodeProgressModel(
      nodeId: _readString(json['nodeId']),
      masteryPoints: _readPositiveInt(json['masteryPoints']),
      completedSourceIds: _readStringList(json['completedSourceIds']),
    );
  }

  int masteryPercent({int masteryTarget = 100}) {
    if (masteryTarget <= 0) return 0;
    final percent = (masteryPoints / masteryTarget * 100).round();
    if (percent < 0) return 0;
    if (percent > 100) return 100;
    return percent;
  }

  bool isMastered({int masteryTarget = 100}) => masteryPercent(masteryTarget: masteryTarget) >= 100;

  SkillNodeProgressModel addProgress({
    required String sourceId,
    required int points,
    int masteryTarget = 100,
  }) {
    if (completedSourceIds.contains(sourceId)) return this;
    final nextPoints = (masteryPoints + points).clamp(0, masteryTarget).toInt();
    return SkillNodeProgressModel(
      nodeId: nodeId,
      masteryPoints: nextPoints,
      completedSourceIds: <String>[...completedSourceIds, sourceId],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nodeId': nodeId,
        'masteryPoints': masteryPoints,
        'completedSourceIds': completedSourceIds,
      };
}

class SkillTreeProgressModel {
  final String roleId;
  final Map<String, SkillNodeProgressModel> nodeProgress;

  const SkillTreeProgressModel({
    required this.roleId,
    this.nodeProgress = const <String, SkillNodeProgressModel>{},
  });

  factory SkillTreeProgressModel.fromJson(Map<String, dynamic> json, {String fallbackRoleId = ''}) {
    final progress = <String, SkillNodeProgressModel>{};
    final items = json['nodeProgress'];
    if (items is Map) {
      items.forEach((key, value) {
        if (key is String && value is Map<String, dynamic>) {
          final node = SkillNodeProgressModel.fromJson(value);
          if (node.nodeId.isNotEmpty) progress[key] = node;
        }
      });
    }
    return SkillTreeProgressModel(
      roleId: _readString(json['roleId']).isNotEmpty ? _readString(json['roleId']) : fallbackRoleId,
      nodeProgress: Map<String, SkillNodeProgressModel>.unmodifiable(progress),
    );
  }

  SkillNodeProgressModel progressFor(String nodeId) {
    return nodeProgress[nodeId] ?? SkillNodeProgressModel(nodeId: nodeId);
  }

  SkillTreeProgressModel upsertNodeProgress(SkillNodeProgressModel progress) {
    final next = Map<String, SkillNodeProgressModel>.from(nodeProgress)
      ..[progress.nodeId] = progress;
    return SkillTreeProgressModel(
      roleId: roleId,
      nodeProgress: Map<String, SkillNodeProgressModel>.unmodifiable(next),
    );
  }

  double masteryPercentForTree(SkillTreeModel tree) {
    if (tree.nodes.isEmpty) return 0;
    final total = tree.nodes.fold<int>(0, (sum, node) {
      return sum + progressFor(node.id).masteryPercent(masteryTarget: node.masteryTarget);
    });
    return total / tree.nodes.length;
  }

  bool isNodeUnlocked(SkillNodeModel node) {
    if (node.prerequisiteNodeIds.isEmpty) return true;
    return node.prerequisiteNodeIds.every((id) => progressFor(id).isMastered());
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roleId': roleId,
        'nodeProgress': nodeProgress.map((key, value) => MapEntry(key, value.toJson())),
      };
}

String _readString(Object? value) => value is String ? value.trim() : '';

int _readPositiveInt(Object? value, {int fallback = 0}) {
  if (value is int && value >= 0) return value;
  if (value is num && value >= 0) return value.toInt();
  return fallback;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList(growable: false);
}
