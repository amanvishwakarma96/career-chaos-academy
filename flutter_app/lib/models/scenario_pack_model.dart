import 'role_model.dart';
import 'role_scenario_model.dart';
import 'scenario_model.dart';

class ScenarioPackCreatorModel {
  final String id;
  final String name;
  final String displayName;
  final bool verified;

  const ScenarioPackCreatorModel({
    this.id = '',
    this.name = '',
    this.displayName = '',
    this.verified = false,
  });

  factory ScenarioPackCreatorModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const ScenarioPackCreatorModel();
    return ScenarioPackCreatorModel(
      id: _readString(json['id']),
      name: _readString(json['name']),
      displayName: _readString(json['displayName'], fallback: _readString(json['name'])),
      verified: json['verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'displayName': displayName,
        'verified': verified,
      };
}

class ScenarioPackRatingModel {
  final double average;
  final int count;
  final int userRating;

  const ScenarioPackRatingModel({this.average = 0, this.count = 0, this.userRating = 0});

  factory ScenarioPackRatingModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const ScenarioPackRatingModel();
    return ScenarioPackRatingModel(
      average: _readDouble(json['average']),
      count: _readInt(json['count']),
      userRating: _readInt(json['userRating']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'average': average,
        'count': count,
        'userRating': userRating,
      };
}

class ScenarioPackCompatibilityModel {
  final String minAppVersion;
  final String maxAppVersion;
  final String schemaVersion;
  final List<String> requiredFeatureFlags;

  const ScenarioPackCompatibilityModel({
    this.minAppVersion = '1.0.0',
    this.maxAppVersion = '',
    this.schemaVersion = 'scenario_pack_v1',
    this.requiredFeatureFlags = const <String>[],
  });

  factory ScenarioPackCompatibilityModel.fromJson(Object? json, {String fallbackMinVersion = '1.0.0'}) {
    if (json is! Map<String, dynamic>) {
      return ScenarioPackCompatibilityModel(minAppVersion: fallbackMinVersion);
    }
    return ScenarioPackCompatibilityModel(
      minAppVersion: _readString(json['minAppVersion'], fallback: fallbackMinVersion),
      maxAppVersion: _readString(json['maxAppVersion']),
      schemaVersion: _readString(json['schemaVersion'], fallback: 'scenario_pack_v1'),
      requiredFeatureFlags: _readStringList(json['requiredFeatureFlags']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'minAppVersion': minAppVersion,
        'maxAppVersion': maxAppVersion,
        'schemaVersion': schemaVersion,
        'requiredFeatureFlags': requiredFeatureFlags,
      };
}

class ScenarioPackSafetyReviewModel {
  final String status;
  final String reviewedBy;
  final String reviewedAt;
  final List<String> domains;
  final List<String> guardrails;
  final String notes;

  const ScenarioPackSafetyReviewModel({
    this.status = 'draft',
    this.reviewedBy = '',
    this.reviewedAt = '',
    this.domains = const <String>[],
    this.guardrails = const <String>[],
    this.notes = '',
  });

  factory ScenarioPackSafetyReviewModel.fromJson(Object? json, {String fallbackStatus = 'draft'}) {
    if (json is! Map<String, dynamic>) {
      return ScenarioPackSafetyReviewModel(status: fallbackStatus);
    }
    return ScenarioPackSafetyReviewModel(
      status: _readString(json['status'], fallback: fallbackStatus),
      reviewedBy: _readString(json['reviewedBy']),
      reviewedAt: _readString(json['reviewedAt']),
      domains: _readStringList(json['domains']),
      guardrails: _readStringList(json['guardrails']),
      notes: _readString(json['notes']),
    );
  }

  bool get isApproved => status == 'approved';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'reviewedBy': reviewedBy,
        'reviewedAt': reviewedAt,
        'domains': domains,
        'guardrails': guardrails,
        'notes': notes,
      };
}

class ScenarioPackOfflineModel {
  final String cacheStrategy;
  final int estimatedSizeKb;
  final String checksum;
  final bool supportsDeltaUpdate;

  const ScenarioPackOfflineModel({
    this.cacheStrategy = 'downloadable_json_pack',
    this.estimatedSizeKb = 0,
    this.checksum = '',
    this.supportsDeltaUpdate = false,
  });

  factory ScenarioPackOfflineModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const ScenarioPackOfflineModel();
    return ScenarioPackOfflineModel(
      cacheStrategy: _readString(json['cacheStrategy'], fallback: 'downloadable_json_pack'),
      estimatedSizeKb: _readInt(json['estimatedSizeKb']),
      checksum: _readString(json['checksum']),
      supportsDeltaUpdate: json['supportsDeltaUpdate'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cacheStrategy': cacheStrategy,
        'estimatedSizeKb': estimatedSizeKb,
        'checksum': checksum,
        'supportsDeltaUpdate': supportsDeltaUpdate,
      };
}

class ScenarioPackModel {
  final String id;
  final String title;
  final String roleId;
  final String roleName;
  final String roleIconKey;
  final String description;
  final String difficulty;
  final ScenarioPackCreatorModel creator;
  final String version;
  final String contentVersion;
  final String minAppVersion;
  final String maxAppVersion;
  final String priceType;
  final String safetyStatus;
  final String reviewStatus;
  final bool isPublished;
  final bool isFeatured;
  final bool isDownloadable;
  final bool supportsOfflineCache;
  final ScenarioPackRatingModel rating;
  final List<Map<String, dynamic>> reviews;
  final List<String> tags;
  final ScenarioPackCompatibilityModel compatibility;
  final ScenarioPackSafetyReviewModel safetyReview;
  final ScenarioPackOfflineModel offline;
  final List<Map<String, dynamic>> chapterJson;

  const ScenarioPackModel({
    required this.id,
    required this.title,
    required this.roleId,
    required this.roleName,
    this.roleIconKey = 'work',
    this.description = '',
    this.difficulty = 'Beginner',
    this.creator = const ScenarioPackCreatorModel(),
    this.version = '1.0.0',
    this.contentVersion = '27.0.0',
    this.minAppVersion = '1.0.0',
    this.maxAppVersion = '',
    this.priceType = 'free',
    this.safetyStatus = 'draft',
    this.reviewStatus = 'draft',
    this.isPublished = false,
    this.isFeatured = false,
    this.isDownloadable = false,
    this.supportsOfflineCache = false,
    this.rating = const ScenarioPackRatingModel(),
    this.reviews = const <Map<String, dynamic>>[],
    this.tags = const <String>[],
    this.compatibility = const ScenarioPackCompatibilityModel(),
    this.safetyReview = const ScenarioPackSafetyReviewModel(),
    this.offline = const ScenarioPackOfflineModel(),
    this.chapterJson = const <Map<String, dynamic>>[],
  });

  factory ScenarioPackModel.fromJson(Map<String, dynamic> json) {
    final roleId = _readString(json['roleId'], fallback: _readString(json['role']));
    final roleName = _readString(json['roleName'], fallback: _titleCase(roleId));
    final minVersion = _readString(json['minAppVersion'], fallback: '1.0.0');
    return ScenarioPackModel(
      id: _readString(json['id']),
      title: _readString(json['title'], fallback: 'Untitled Scenario Pack'),
      roleId: roleId,
      roleName: roleName,
      roleIconKey: _readString(json['roleIconKey'], fallback: 'work'),
      description: _readString(json['description']),
      difficulty: _readString(json['difficulty'], fallback: 'Beginner'),
      creator: ScenarioPackCreatorModel.fromJson(json['creator']),
      version: _readString(json['version'], fallback: '1.0.0'),
      contentVersion: _readString(json['contentVersion'], fallback: '27.0.0'),
      minAppVersion: minVersion,
      maxAppVersion: _readString(json['maxAppVersion']),
      priceType: _readString(json['priceType'], fallback: 'free'),
      safetyStatus: _readString(json['safetyStatus'], fallback: _readString(json['reviewStatus'], fallback: 'draft')),
      reviewStatus: _readString(json['reviewStatus'], fallback: _readString(json['safetyStatus'], fallback: 'draft')),
      isPublished: json['isPublished'] == true,
      isFeatured: json['isFeatured'] == true,
      isDownloadable: json['isDownloadable'] == true,
      supportsOfflineCache: json['supportsOfflineCache'] == true,
      rating: ScenarioPackRatingModel.fromJson(json['rating']),
      reviews: _readMapList(json['reviews']),
      tags: _readStringList(json['tags']),
      compatibility: ScenarioPackCompatibilityModel.fromJson(json['compatibility'], fallbackMinVersion: minVersion),
      safetyReview: ScenarioPackSafetyReviewModel.fromJson(json['safetyReview'], fallbackStatus: _readString(json['safetyStatus'], fallback: 'draft')),
      offline: ScenarioPackOfflineModel.fromJson(json['offline']),
      chapterJson: _readMapList(json['chapters']),
    );
  }

  bool get isFree => priceType == 'free';
  bool get isApproved => safetyStatus == 'approved' && safetyReview.isApproved;
  bool get canPublish => chapterJson.isNotEmpty && isApproved;
  int get chapterCount => chapterJson.length;

  bool isCompatibleWithApp({required String appVersion, bool Function(String key)? featureEnabled}) {
    if (!_versionAtLeast(appVersion, compatibility.minAppVersion.isNotEmpty ? compatibility.minAppVersion : minAppVersion)) {
      return false;
    }
    if (compatibility.maxAppVersion.isNotEmpty && !_versionAtLeast(compatibility.maxAppVersion, appVersion)) {
      return false;
    }
    for (final flag in compatibility.requiredFeatureFlags) {
      if (featureEnabled != null && !featureEnabled(flag)) return false;
    }
    return true;
  }

  RoleScenarioModel toRoleScenario() {
    final role = RoleModel(
      id: roleId,
      name: roleName,
      description: description.isNotEmpty ? description : 'Creator pack for $roleName.',
      iconKey: roleIconKey,
      pluginId: '${roleId}_creator_pack',
      contentPackId: id,
      contentVersion: contentVersion,
      contentTier: priceType,
    );
    final chapters = chapterJson
        .map((chapter) => ScenarioModel.fromJson(
              <String, dynamic>{
                ...chapter,
                'contentPackId': chapter['contentPackId'] ?? id,
                'contentVersion': chapter['contentVersion'] ?? contentVersion,
                'contentTier': chapter['contentTier'] ?? priceType,
                'safetyReview': chapter['safetyReview'] ?? safetyReview.toJson(),
              },
              role: role,
            ))
        .toList(growable: false);
    return RoleScenarioModel(role: role, chapters: chapters);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'roleId': roleId,
        'roleName': roleName,
        'roleIconKey': roleIconKey,
        'description': description,
        'difficulty': difficulty,
        'creator': creator.toJson(),
        'version': version,
        'contentVersion': contentVersion,
        'minAppVersion': minAppVersion,
        'maxAppVersion': maxAppVersion,
        'priceType': priceType,
        'safetyStatus': safetyStatus,
        'reviewStatus': reviewStatus,
        'isPublished': isPublished,
        'isFeatured': isFeatured,
        'isDownloadable': isDownloadable,
        'supportsOfflineCache': supportsOfflineCache,
        'rating': rating.toJson(),
        'reviews': reviews,
        'tags': tags,
        'compatibility': compatibility.toJson(),
        'safetyReview': safetyReview.toJson(),
        'offline': offline.toJson(),
        'chapters': chapterJson,
      };
}

class ScenarioPackCatalogModel {
  final int version;
  final List<ScenarioPackModel> packs;

  const ScenarioPackCatalogModel({this.version = 1, this.packs = const <ScenarioPackModel>[]});

  factory ScenarioPackCatalogModel.fromJson(Map<String, dynamic> json) {
    final rawPacks = json['packs'];
    return ScenarioPackCatalogModel(
      version: _readInt(json['version'], fallback: 1),
      packs: rawPacks is List
          ? rawPacks
              .whereType<Map<String, dynamic>>()
              .map(ScenarioPackModel.fromJson)
              .toList(growable: false)
          : const <ScenarioPackModel>[],
    );
  }
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

double _readDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return 0;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList(growable: false);
}

List<Map<String, dynamic>> _readMapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

String _titleCase(String value) {
  if (value.isEmpty) return 'Creator Role';
  return value.split('_').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
}

bool _versionAtLeast(String current, String minimum) {
  final a = current.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  final b = minimum.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  for (var i = 0; i < 3; i += 1) {
    final av = i < a.length ? a[i] : 0;
    final bv = i < b.length ? b[i] : 0;
    if (av > bv) return true;
    if (av < bv) return false;
  }
  return true;
}
