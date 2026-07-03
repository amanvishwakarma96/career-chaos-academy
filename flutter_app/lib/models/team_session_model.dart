class TeamRoleOptionModel {
  final String id;
  final String name;
  final String iconKey;
  final String description;

  const TeamRoleOptionModel({
    required this.id,
    required this.name,
    this.iconKey = 'work',
    this.description = '',
  });

  factory TeamRoleOptionModel.fromJson(Map<String, dynamic> json) {
    return TeamRoleOptionModel(
      id: _readString(json['id']),
      name: _readString(json['name'], fallback: _readString(json['id'])),
      iconKey: _readString(json['iconKey'], fallback: 'work'),
      description: _readString(json['description']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'description': description,
      };
}

class TeamParticipantModel {
  final String userId;
  final String displayName;
  final String selectedRoleId;
  final bool isHost;
  final String joinedAt;
  final String lastActiveAt;

  const TeamParticipantModel({
    required this.userId,
    required this.displayName,
    this.selectedRoleId = '',
    this.isHost = false,
    this.joinedAt = '',
    this.lastActiveAt = '',
  });

  bool get hasSelectedRole => selectedRoleId.trim().isNotEmpty;

  factory TeamParticipantModel.fromJson(Map<String, dynamic> json) {
    return TeamParticipantModel(
      userId: _readString(json['userId']),
      displayName: _readString(json['displayName'], fallback: 'Player'),
      selectedRoleId: _readString(json['selectedRoleId']),
      isHost: json['isHost'] == true,
      joinedAt: _readString(json['joinedAt']),
      lastActiveAt: _readString(json['lastActiveAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'displayName': displayName,
        'selectedRoleId': selectedRoleId,
        'isHost': isHost,
        'joinedAt': joinedAt,
        'lastActiveAt': lastActiveAt,
      };
}

class TeamScenarioChoiceModel {
  final int index;
  final String text;

  const TeamScenarioChoiceModel({required this.index, required this.text});

  factory TeamScenarioChoiceModel.fromJson(Map<String, dynamic> json) {
    return TeamScenarioChoiceModel(
      index: _readInt(json['index']),
      text: _readString(json['text'], fallback: 'Choice'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'index': index,
        'text': text,
      };
}

class TeamScenarioSummaryModel {
  final String roleId;
  final String chapterId;
  final String title;
  final String story;
  final String task;
  final List<TeamScenarioChoiceModel> choices;

  const TeamScenarioSummaryModel({
    this.roleId = '',
    this.chapterId = '',
    this.title = 'Team Scenario',
    this.story = '',
    this.task = '',
    this.choices = const <TeamScenarioChoiceModel>[],
  });

  factory TeamScenarioSummaryModel.fromJson(Map<String, dynamic> json) {
    final items = json['choices'] is List ? json['choices'] as List : const <Object?>[];
    return TeamScenarioSummaryModel(
      roleId: _readString(json['roleId']),
      chapterId: _readString(json['chapterId']),
      title: _readString(json['title'], fallback: 'Team Scenario'),
      story: _readString(json['story']),
      task: _readString(json['task']),
      choices: items
          .whereType<Map<String, dynamic>>()
          .map(TeamScenarioChoiceModel.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roleId': roleId,
        'chapterId': chapterId,
        'title': title,
        'story': story,
        'task': task,
        'choices': choices.map((choice) => choice.toJson()).toList(growable: false),
      };
}

class TeamTurnModel {
  final String currentParticipantId;
  final int currentTurnIndex;
  final int roundIndex;
  final int maxRounds;
  final String status;
  final String? startedAt;

  const TeamTurnModel({
    this.currentParticipantId = '',
    this.currentTurnIndex = 0,
    this.roundIndex = 0,
    this.maxRounds = 1,
    this.status = 'waiting_for_roles',
    this.startedAt,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  int get displayRound => roundIndex + 1;

  factory TeamTurnModel.fromJson(Map<String, dynamic> json) {
    return TeamTurnModel(
      currentParticipantId: _readString(json['currentParticipantId']),
      currentTurnIndex: _readInt(json['currentTurnIndex']),
      roundIndex: _readInt(json['roundIndex']),
      maxRounds: _readInt(json['maxRounds'], fallback: 1),
      status: _readString(json['status'], fallback: 'waiting_for_roles'),
      startedAt: json['startedAt'] is String ? json['startedAt'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentParticipantId': currentParticipantId,
        'currentTurnIndex': currentTurnIndex,
        'roundIndex': roundIndex,
        'maxRounds': maxRounds,
        'status': status,
        'startedAt': startedAt,
      };
}

class TeamScoreModel {
  final int collaboration;
  final int communication;
  final int speed;
  final int accuracy;
  final int ethics;

  const TeamScoreModel({
    this.collaboration = 0,
    this.communication = 0,
    this.speed = 0,
    this.accuracy = 0,
    this.ethics = 0,
  });

  static const TeamScoreModel zero = TeamScoreModel();

  int get total => ((collaboration + communication + speed + accuracy + ethics) / 5).round();

  factory TeamScoreModel.fromJson(Map<String, dynamic> json) {
    return TeamScoreModel(
      collaboration: _readInt(json['collaboration']),
      communication: _readInt(json['communication']),
      speed: _readInt(json['speed']),
      accuracy: _readInt(json['accuracy']),
      ethics: _readInt(json['ethics']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'collaboration': collaboration,
        'communication': communication,
        'speed': speed,
        'accuracy': accuracy,
        'ethics': ethics,
      };
}

class TeamDecisionModel {
  final String id;
  final int roundIndex;
  final int turnIndex;
  final String userId;
  final String displayName;
  final String roleId;
  final int choiceIndex;
  final String choiceText;
  final String outcomeTitle;
  final String outcomeSummary;
  final List<String> affectedRoles;
  final List<String> setFlags;
  final List<String> clearFlags;
  final String createdAt;
  final int elapsedSeconds;

  const TeamDecisionModel({
    required this.id,
    this.roundIndex = 0,
    this.turnIndex = 0,
    this.userId = '',
    this.displayName = '',
    this.roleId = '',
    this.choiceIndex = 0,
    this.choiceText = '',
    this.outcomeTitle = '',
    this.outcomeSummary = '',
    this.affectedRoles = const <String>[],
    this.setFlags = const <String>[],
    this.clearFlags = const <String>[],
    this.createdAt = '',
    this.elapsedSeconds = 0,
  });

  factory TeamDecisionModel.fromJson(Map<String, dynamic> json) {
    return TeamDecisionModel(
      id: _readString(json['id']),
      roundIndex: _readInt(json['roundIndex']),
      turnIndex: _readInt(json['turnIndex']),
      userId: _readString(json['userId']),
      displayName: _readString(json['displayName']),
      roleId: _readString(json['roleId']),
      choiceIndex: _readInt(json['choiceIndex']),
      choiceText: _readString(json['choiceText']),
      outcomeTitle: _readString(json['outcomeTitle']),
      outcomeSummary: _readString(json['outcomeSummary']),
      affectedRoles: _readStringList(json['affectedRoles']),
      setFlags: _readStringList(json['setFlags']),
      clearFlags: _readStringList(json['clearFlags']),
      createdAt: _readString(json['createdAt']),
      elapsedSeconds: _readInt(json['elapsedSeconds']),
    );
  }
}

class TeamDebriefModel {
  final String appearedAt;
  final int total;
  final String summary;
  final TeamScoreModel scoreBreakdown;
  final List<Map<String, dynamic>> keyMoments;
  final Map<String, List<String>> roleImpacts;
  final List<String> teamFlags;
  final List<String> recommendations;

  const TeamDebriefModel({
    this.appearedAt = '',
    this.total = 0,
    this.summary = '',
    this.scoreBreakdown = TeamScoreModel.zero,
    this.keyMoments = const <Map<String, dynamic>>[],
    this.roleImpacts = const <String, List<String>>{},
    this.teamFlags = const <String>[],
    this.recommendations = const <String>[],
  });

  factory TeamDebriefModel.fromJson(Map<String, dynamic> json) {
    final moments = json['keyMoments'] is List ? json['keyMoments'] as List : const <Object?>[];
    return TeamDebriefModel(
      appearedAt: _readString(json['appearedAt']),
      total: _readInt(json['total']),
      summary: _readString(json['summary']),
      scoreBreakdown: json['scoreBreakdown'] is Map<String, dynamic>
          ? TeamScoreModel.fromJson(json['scoreBreakdown'] as Map<String, dynamic>)
          : TeamScoreModel.zero,
      keyMoments: moments.whereType<Map<String, dynamic>>().toList(growable: false),
      roleImpacts: _readStringListMap(json['roleImpacts']),
      teamFlags: _readStringList(json['teamFlags']),
      recommendations: _readStringList(json['recommendations']),
    );
  }
}

class TeamSessionModel {
  final String id;
  final String roomCode;
  final String joinLink;
  final String title;
  final String mode;
  final String status;
  final String hostUserId;
  final TeamScenarioSummaryModel scenario;
  final List<TeamRoleOptionModel> rolePool;
  final List<TeamParticipantModel> participants;
  final Map<String, String> selectedRoles;
  final TeamTurnModel turn;
  final List<TeamDecisionModel> decisions;
  final List<String> teamFlags;
  final Map<String, List<String>> roleImpacts;
  final TeamScoreModel teamScore;
  final TeamDebriefModel? debrief;
  final String createdAt;
  final String updatedAt;
  final String expiresAt;

  const TeamSessionModel({
    required this.id,
    required this.roomCode,
    this.joinLink = '',
    this.title = 'Team Simulation Room',
    this.mode = 'turn_based_team',
    this.status = 'lobby',
    this.hostUserId = '',
    this.scenario = const TeamScenarioSummaryModel(),
    this.rolePool = const <TeamRoleOptionModel>[],
    this.participants = const <TeamParticipantModel>[],
    this.selectedRoles = const <String, String>{},
    this.turn = const TeamTurnModel(),
    this.decisions = const <TeamDecisionModel>[],
    this.teamFlags = const <String>[],
    this.roleImpacts = const <String, List<String>>{},
    this.teamScore = TeamScoreModel.zero,
    this.debrief,
    this.createdAt = '',
    this.updatedAt = '',
    this.expiresAt = '',
  });

  bool get isLobby => status == 'lobby';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get hasSelectedParticipants => participants.any((participant) => participant.hasSelectedRole);

  TeamParticipantModel? participantByUserId(String userId) {
    for (final participant in participants) {
      if (participant.userId == userId) return participant;
    }
    return null;
  }

  TeamParticipantModel? get currentParticipant {
    final currentId = turn.currentParticipantId;
    if (currentId.isEmpty) return null;
    return participantByUserId(currentId);
  }

  bool isCurrentTurn(String userId) => isInProgress && turn.currentParticipantId == userId;

  Set<String> get selectedRoleIds => participants
      .map((participant) => participant.selectedRoleId)
      .where((roleId) => roleId.isNotEmpty)
      .toSet();

  bool isRoleTakenByOther(String roleId, String userId) {
    return participants.any((participant) => participant.userId != userId && participant.selectedRoleId == roleId);
  }

  factory TeamSessionModel.fromJson(Map<String, dynamic> json) {
    final roleItems = json['rolePool'] is List ? json['rolePool'] as List : const <Object?>[];
    final participantItems = json['participants'] is List ? json['participants'] as List : const <Object?>[];
    final decisionItems = json['decisions'] is List ? json['decisions'] as List : const <Object?>[];
    return TeamSessionModel(
      id: _readString(json['id']),
      roomCode: _readString(json['roomCode']),
      joinLink: _readString(json['joinLink']),
      title: _readString(json['title'], fallback: 'Team Simulation Room'),
      mode: _readString(json['mode'], fallback: 'turn_based_team'),
      status: _readString(json['status'], fallback: 'lobby'),
      hostUserId: _readString(json['hostUserId']),
      scenario: json['scenario'] is Map<String, dynamic>
          ? TeamScenarioSummaryModel.fromJson(json['scenario'] as Map<String, dynamic>)
          : const TeamScenarioSummaryModel(),
      rolePool: roleItems
          .whereType<Map<String, dynamic>>()
          .map(TeamRoleOptionModel.fromJson)
          .toList(growable: false),
      participants: participantItems
          .whereType<Map<String, dynamic>>()
          .map(TeamParticipantModel.fromJson)
          .toList(growable: false),
      selectedRoles: _readStringMap(json['selectedRoles']),
      turn: json['turn'] is Map<String, dynamic>
          ? TeamTurnModel.fromJson(json['turn'] as Map<String, dynamic>)
          : const TeamTurnModel(),
      decisions: decisionItems
          .whereType<Map<String, dynamic>>()
          .map(TeamDecisionModel.fromJson)
          .toList(growable: false),
      teamFlags: _readStringList(json['teamFlags']),
      roleImpacts: _readStringListMap(json['roleImpacts']),
      teamScore: json['teamScore'] is Map<String, dynamic>
          ? TeamScoreModel.fromJson(json['teamScore'] as Map<String, dynamic>)
          : TeamScoreModel.zero,
      debrief: json['debrief'] is Map<String, dynamic>
          ? TeamDebriefModel.fromJson(json['debrief'] as Map<String, dynamic>)
          : null,
      createdAt: _readString(json['createdAt']),
      updatedAt: _readString(json['updatedAt']),
      expiresAt: _readString(json['expiresAt']),
    );
  }
}

String _readString(Object? value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().where((item) => item.trim().isNotEmpty).toList(growable: false);
}

Map<String, String> _readStringMap(Object? value) {
  if (value is! Map) return const <String, String>{};
  final output = <String, String>{};
  value.forEach((key, item) {
    if (key is String && item is String) output[key] = item;
  });
  return Map<String, String>.unmodifiable(output);
}

Map<String, List<String>> _readStringListMap(Object? value) {
  if (value is! Map) return const <String, List<String>>{};
  final output = <String, List<String>>{};
  value.forEach((key, item) {
    if (key is String) output[key] = _readStringList(item);
  });
  return Map<String, List<String>>.unmodifiable(output);
}
