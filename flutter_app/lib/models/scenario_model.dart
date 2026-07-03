import '../core/json_reader.dart';
import 'choice_model.dart';
import 'dialogue_scene_model.dart';
import 'ending_rule_model.dart';
import 'mini_game_model.dart';
import 'relationship_score_model.dart';
import 'professional/professional_context_model.dart';
import 'role_model.dart';
import 'story_flag_model.dart';
import 'score_model.dart';
import 'future_scope/access_models.dart';
import 'future_scope/localization_models.dart';
import 'future_scope/multiplayer_models.dart';
import 'future_scope/safety_review_model.dart';
import 'adaptive/adaptive_story_model.dart';

class ScenarioModel {
  final String id;
  final RoleModel role;
  final String title;
  final String difficulty;
  final String theme;
  final String story;
  final String task;
  final String professionalLearningPoint;
  final String? safetyDisclaimer;
  final List<ChoiceModel> choices;
  final List<DialogueSceneModel> scenes;
  final MiniGameModel? miniGame;
  final List<String> prerequisites;
  final List<String> consequenceFlags;
  final List<String> blockedByFlags;
  final ScoreModel? requiredScoreMinimums;
  final String? roleMechanicType;
  final bool isCleanupMission;
  final bool isFinale;
  final List<StoryFlagModel> storyFlags;
  final List<String> requiredStoryFlags;
  final List<String> blockedByStoryFlags;
  final RelationshipScoreModel? requiredRelationshipMinimums;
  final List<EndingRuleModel> endingRules;
  final ProfessionalContextModel professionalContext;
  final String contentVersion;
  final String contentPackId;
  final String assetVersion;
  final String assetPackId;
  final String rolePluginId;
  final LocalizedTextRefModel localization;
  final ContentAccessModel contentAccess;
  final SafetyReviewModel safetyReview;
  final List<String> analyticsTags;
  final bool supportsOfflineCache;
  final MultiplayerPlaceholderModel multiplayer;
  final List<AdaptiveDialogueInjectionModel> adaptiveDialogueInjections;
  final AdaptiveDifficultyConfigModel adaptiveDifficulty;
  final bool allowsAdaptiveSideMissions;
  final List<String> skillNodeIds;

  const ScenarioModel({
    required this.id,
    required this.role,
    required this.title,
    required this.difficulty,
    required this.theme,
    required this.story,
    required this.task,
    this.professionalLearningPoint = '',
    this.safetyDisclaimer,
    required this.choices,
    this.scenes = const <DialogueSceneModel>[],
    this.miniGame,
    this.prerequisites = const <String>[],
    this.consequenceFlags = const <String>[],
    this.blockedByFlags = const <String>[],
    this.requiredScoreMinimums,
    this.roleMechanicType,
    this.isCleanupMission = false,
    this.isFinale = false,
    this.storyFlags = const <StoryFlagModel>[],
    this.requiredStoryFlags = const <String>[],
    this.blockedByStoryFlags = const <String>[],
    this.requiredRelationshipMinimums,
    this.endingRules = const <EndingRuleModel>[],
    this.professionalContext = ProfessionalContextModel.empty,
    this.contentVersion = '',
    this.contentPackId = 'core_roles_v23',
    this.assetVersion = '',
    this.assetPackId = 'base_visuals_v23',
    this.rolePluginId = '',
    this.localization = const LocalizedTextRefModel(),
    this.contentAccess = ContentAccessModel.free,
    this.safetyReview = SafetyReviewModel.draft,
    this.analyticsTags = const <String>[],
    this.supportsOfflineCache = true,
    this.multiplayer = const MultiplayerPlaceholderModel(),
    this.adaptiveDialogueInjections = const <AdaptiveDialogueInjectionModel>[],
    this.adaptiveDifficulty = AdaptiveDifficultyConfigModel.defaults,
    this.allowsAdaptiveSideMissions = false,
    this.skillNodeIds = const <String>[],
  });

  factory ScenarioModel.fromJson(
    Map<String, dynamic> json, {
    required RoleModel role,
  }) {
    final choiceItems = JsonReader.readList(
      json,
      'choices',
      parent: 'chapter',
    );

    return ScenarioModel(
      id: JsonReader.readString(json, 'id', parent: 'chapter'),
      role: role,
      title: JsonReader.readString(json, 'title', parent: 'chapter'),
      difficulty: JsonReader.readString(
        json,
        'difficulty',
        parent: 'chapter',
      ),
      theme: JsonReader.readString(json, 'theme', parent: 'chapter'),
      story: _readStory(json),
      task: JsonReader.readString(json, 'task', parent: 'chapter'),
      professionalLearningPoint: _readOptionalString(
        json['professionalLearningPoint'],
      ),
      safetyDisclaimer: _readNullableString(json['safetyDisclaimer']),
      scenes: _readScenes(json['scenes']),
      choices: choiceItems.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('chapter.choices item must be an object.');
        }
        return ChoiceModel.fromJson(item);
      }).toList(growable: false),
      miniGame: _readMiniGame(json['miniGame']),
      prerequisites: _readStringList(json['prerequisites']),
      consequenceFlags: _readStringList(json['consequenceFlags']),
      blockedByFlags: _readStringList(json['blockedByFlags']),
      requiredScoreMinimums: _readScore(json['requiredScoreMinimums']),
      roleMechanicType: _readNullableString(json['roleMechanicType']),
      isCleanupMission: _readBool(json['isCleanupMission']),
      isFinale: _readBool(json['isFinale']),
      storyFlags: _readStoryFlags(json['storyFlags']),
      requiredStoryFlags: _readStringList(json['requiredStoryFlags']),
      blockedByStoryFlags: _readStringList(json['blockedByStoryFlags']),
      requiredRelationshipMinimums: _readRelationship(json['requiredRelationshipMinimums']),
      endingRules: _readEndingRules(json['endingRules']),
      professionalContext: _readProfessionalContext(json),
      contentVersion: _readOptionalString(json['contentVersion']),
      contentPackId: _readOptionalString(json['contentPackId']).isNotEmpty
          ? _readOptionalString(json['contentPackId'])
          : 'core_roles_v23',
      assetVersion: _readOptionalString(json['assetVersion']),
      assetPackId: _readOptionalString(json['assetPackId']).isNotEmpty
          ? _readOptionalString(json['assetPackId'])
          : 'base_visuals_v23',
      rolePluginId: _readOptionalString(json['rolePluginId']),
      localization: LocalizedTextRefModel.fromJson(json['localization'] ?? json['localizationKey']),
      contentAccess: _readContentAccess(json),
      safetyReview: _readSafetyReview(json['safetyReview']),
      analyticsTags: _readStringList(json['analyticsTags']),
      supportsOfflineCache: json['supportsOfflineCache'] is bool
          ? json['supportsOfflineCache'] as bool
          : true,
      multiplayer: _readMultiplayer(json['multiplayer']),
      adaptiveDialogueInjections: _readAdaptiveDialogueInjections(json['adaptiveDialogueInjections']),
      adaptiveDifficulty: AdaptiveDifficultyConfigModel.fromJson(json['adaptiveDifficulty']),
      allowsAdaptiveSideMissions: json['allowsAdaptiveSideMissions'] is bool
          ? json['allowsAdaptiveSideMissions'] as bool
          : false,
      skillNodeIds: _readStringList(json['skillNodeIds']),
    );
  }

  bool get hasCinematicScenes => scenes.any((scene) => scene.hasDialogues);

  String get learningObjective => professionalContext.learningObjective;
  String get skillLevel => professionalContext.skillLevel;
  String get workflowId => professionalContext.workflowId;
  List<String> get skillTags => professionalContext.skillTags;
  List<String> get realWorldConstraints => professionalContext.realWorldConstraints;
  List<String> get safetyGuardrails => professionalContext.safetyGuardrails;
  String get practicalTakeaway => professionalContext.practicalTakeaway;
  String get safeExplanation => professionalContext.safeExplanation;
  String get mentorFeedback => professionalContext.mentorFeedback;
  String get localizationKey => localization.key;
  String get contentTier => contentAccess.tier.name;
}


String _readStory(Map<String, dynamic> json) {
  final story = _readNullableString(json['story']);
  if (story != null) {
    return story;
  }

  final scenario = _readNullableString(json['scenario']);
  if (scenario != null) {
    return scenario;
  }

  final scenes = _readScenes(json['scenes']);
  for (final scene in scenes) {
    for (final line in scene.dialogues) {
      if (line.text.isNotEmpty) {
        return line.text;
      }
    }
  }

  throw const FormatException('chapter.story, chapter.scenario, or chapter.scenes.dialogues is required.');
}


List<DialogueSceneModel> _readScenes(Object? value) {
  if (value is! List) {
    return const <DialogueSceneModel>[];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(DialogueSceneModel.fromJson)
      .where((scene) => scene.hasDialogues)
      .toList(growable: false);
}

String _readOptionalString(Object? value) {
  return _readNullableString(value) ?? '';
}

String? _readNullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }
  return false;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

ScoreModel? _readScore(Object? value) {
  if (value is Map<String, dynamic>) {
    return ScoreModel.fromJson(value);
  }
  return null;
}

MiniGameModel? _readMiniGame(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! Map<String, dynamic>) {
    throw const FormatException('chapter.miniGame must be an object.');
  }
  return MiniGameModel.fromJson(value);
}



ProfessionalContextModel _readProfessionalContext(Map<String, dynamic> json) {
  final professional = json['professionalContext'];
  final source = <String, dynamic>{};
  if (professional is Map<String, dynamic>) {
    source.addAll(professional);
  }
  for (final key in <String>[
    'learningObjective',
    'skillLevel',
    'workflowId',
    'skillTags',
    'realWorldConstraints',
    'safetyGuardrails',
    'practicalTakeaway',
    'safeExplanation',
    'mentorFeedback',
  ]) {
    if (json.containsKey(key)) {
      source[key] = json[key];
    }
  }
  return source.isEmpty
      ? ProfessionalContextModel.empty
      : ProfessionalContextModel.fromJson(source);
}

List<StoryFlagModel> _readStoryFlags(Object? value) {
  if (value is! List) {
    return const <StoryFlagModel>[];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(StoryFlagModel.fromJson)
      .where((flag) => flag.id.isNotEmpty)
      .toList(growable: false);
}

RelationshipScoreModel? _readRelationship(Object? value) {
  if (value is Map<String, dynamic>) {
    return RelationshipScoreModel.fromJson(value);
  }
  return null;
}

List<EndingRuleModel> _readEndingRules(Object? value) {
  if (value is! List) {
    return const <EndingRuleModel>[];
  }
  final rules = value
      .whereType<Map<String, dynamic>>()
      .map(EndingRuleModel.fromJson)
      .where((rule) => rule.id.isNotEmpty)
      .toList(growable: true);
  rules.sort((a, b) => b.priority.compareTo(a.priority));
  return List<EndingRuleModel>.unmodifiable(rules);
}

SafetyReviewModel _readSafetyReview(Object? value) {
  if (value is Map<String, dynamic>) {
    return SafetyReviewModel.fromJson(value);
  }
  return SafetyReviewModel.draft;
}

ContentAccessModel _readContentAccess(Map<String, dynamic> json) {
  final access = json['contentAccess'];
  if (access is Map<String, dynamic>) {
    return ContentAccessModel.fromJson(access);
  }
  return ContentAccessModel.fromJson(<String, dynamic>{
    'tier': json['contentTier'] ?? 'free',
    'isLockedPlaceholder': json['isLockedPlaceholder'] ?? false,
    'unlockHint': json['unlockHint'] ?? '',
  });
}

MultiplayerPlaceholderModel _readMultiplayer(Object? value) {
  if (value is Map<String, dynamic>) {
    return MultiplayerPlaceholderModel.fromJson(value);
  }
  return const MultiplayerPlaceholderModel();
}


List<AdaptiveDialogueInjectionModel> _readAdaptiveDialogueInjections(Object? value) {
  if (value is! List) {
    return const <AdaptiveDialogueInjectionModel>[];
  }
  final injections = value
      .whereType<Map<String, dynamic>>()
      .map(AdaptiveDialogueInjectionModel.fromJson)
      .where((item) => item.id.isNotEmpty && item.text.isNotEmpty)
      .toList(growable: true);
  injections.sort((a, b) => b.priority.compareTo(a.priority));
  return List<AdaptiveDialogueInjectionModel>.unmodifiable(injections);
}
