import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/choice_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../models/team_session_model.dart';
import 'api_client.dart';
import 'scenario_service.dart';

class TeamSessionService {
  TeamSessionService._();

  static final TeamSessionService instance = TeamSessionService._();
  static const String _localSessionsKey = 'career_chaos_team_sessions_v1';

  Future<TeamSessionModel> createRoom({
    required String userId,
    required String displayName,
    String title = 'Team Simulation Room',
    String? roleId,
    String? chapterId,
    int maxRounds = 1,
  }) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/team-sessions', <String, dynamic>{
          'hostUserId': userId,
          'hostDisplayName': displayName,
          'title': title,
          if (roleId != null) 'roleId': roleId,
          if (chapterId != null) 'chapterId': chapterId,
          'maxRounds': maxRounds,
        });
        return TeamSessionModel.fromJson(json);
      } on Object {
        // Fall through to local simulation so development builds remain playable.
      }
    }
    return _createLocalRoom(
      userId: userId,
      displayName: displayName,
      title: title,
      roleId: roleId,
      chapterId: chapterId,
      maxRounds: maxRounds,
    );
  }

  Future<TeamSessionModel> joinByCode({
    required String roomCode,
    required String userId,
    required String displayName,
  }) async {
    final normalizedCode = roomCode.trim().toUpperCase();
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/team-sessions/join', <String, dynamic>{
          'roomCode': normalizedCode,
          'userId': userId,
          'displayName': displayName,
        });
        return TeamSessionModel.fromJson(json);
      } on Object {
        // Fall through to local room lookup.
      }
    }
    final sessions = await _loadLocalSessions();
    final session = sessions[normalizedCode];
    if (session == null) {
      throw const TeamSessionException('Team room not found. Create a room or check the code again.');
    }
    final updated = _withParticipant(session, userId: userId, displayName: displayName);
    sessions[normalizedCode] = updated;
    await _saveLocalSessions(sessions);
    return updated;
  }

  Future<TeamSessionModel> getSession(String sessionId, {String? roomCode}) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/team-sessions/${Uri.encodeComponent(sessionId)}');
        return TeamSessionModel.fromJson(json);
      } on Object {
        // Fall through to local lookup.
      }
    }
    final sessions = await _loadLocalSessions();
    for (final session in sessions.values) {
      if (session.id == sessionId || session.roomCode == roomCode) return session;
    }
    throw const TeamSessionException('Team session not found.');
  }

  Future<TeamSessionModel> selectRole({
    required String sessionId,
    required String userId,
    required String roleId,
    String? roomCode,
  }) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap(
          '/api/team-sessions/${Uri.encodeComponent(sessionId)}/select-role',
          <String, dynamic>{'userId': userId, 'roleId': roleId},
        );
        return TeamSessionModel.fromJson(json);
      } on Object {
        // Fall through to local update.
      }
    }
    final sessions = await _loadLocalSessions();
    final session = _findLocalSession(sessions, sessionId: sessionId, roomCode: roomCode);
    if (session == null) throw const TeamSessionException('Team session not found.');
    if (session.isRoleTakenByOther(roleId, userId)) {
      throw const TeamSessionException('This role is already selected by another teammate.');
    }
    final participants = session.participants.map((participant) {
      if (participant.userId != userId) return participant;
      return TeamParticipantModel(
        userId: participant.userId,
        displayName: participant.displayName,
        selectedRoleId: roleId,
        isHost: participant.isHost,
        joinedAt: participant.joinedAt,
        lastActiveAt: DateTime.now().toIso8601String(),
      );
    }).toList(growable: false);
    final selectedRoles = <String, String>{...session.selectedRoles, userId: roleId};
    final updated = _copySession(session, participants: participants, selectedRoles: selectedRoles);
    sessions[updated.roomCode] = updated;
    await _saveLocalSessions(sessions);
    return updated;
  }

  Future<TeamSessionModel> startSession({
    required String sessionId,
    required String userId,
    String? roomCode,
  }) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap(
          '/api/team-sessions/${Uri.encodeComponent(sessionId)}/start',
          <String, dynamic>{'userId': userId},
        );
        return TeamSessionModel.fromJson(json);
      } on Object {
        // Fall through to local start.
      }
    }
    final sessions = await _loadLocalSessions();
    final session = _findLocalSession(sessions, sessionId: sessionId, roomCode: roomCode);
    if (session == null) throw const TeamSessionException('Team session not found.');
    final selected = session.participants.where((participant) => participant.hasSelectedRole).toList(growable: false);
    if (selected.isEmpty) throw const TeamSessionException('Select at least one role before starting.');
    final updated = _copySession(
      session,
      status: 'in_progress',
      turn: TeamTurnModel(
        currentParticipantId: selected.first.userId,
        currentTurnIndex: 0,
        roundIndex: 0,
        maxRounds: session.turn.maxRounds,
        status: 'active',
        startedAt: DateTime.now().toIso8601String(),
      ),
    );
    sessions[updated.roomCode] = updated;
    await _saveLocalSessions(sessions);
    return updated;
  }

  Future<TeamSessionModel> submitDecision({
    required String sessionId,
    required String userId,
    required int choiceIndex,
    String? roomCode,
  }) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap(
          '/api/team-sessions/${Uri.encodeComponent(sessionId)}/decisions',
          <String, dynamic>{'userId': userId, 'choiceIndex': choiceIndex},
        );
        return TeamSessionModel.fromJson(json);
      } on Object {
        // Fall through to local simulation.
      }
    }
    return _submitLocalDecision(sessionId: sessionId, userId: userId, choiceIndex: choiceIndex, roomCode: roomCode);
  }

  Future<TeamSessionModel> _createLocalRoom({
    required String userId,
    required String displayName,
    required String title,
    String? roleId,
    String? chapterId,
    required int maxRounds,
  }) async {
    final result = await ScenarioService.instance.loadScenarios(preferApi: false);
    if (result.roles.isEmpty) throw const TeamSessionException('No local scenarios are available.');
    final scenarioPair = _pickScenario(result.roles, roleId: roleId, chapterId: chapterId);
    final roleScenario = scenarioPair.$1;
    final scenario = scenarioPair.$2;
    final sessions = await _loadLocalSessions();
    var roomCode = _roomCode();
    while (sessions.containsKey(roomCode)) {
      roomCode = _roomCode();
    }
    final now = DateTime.now().toIso8601String();
    final session = TeamSessionModel(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      roomCode: roomCode,
      joinLink: '/team/join/$roomCode',
      title: title,
      hostUserId: userId,
      scenario: TeamScenarioSummaryModel(
        roleId: roleScenario.role.id,
        chapterId: scenario.id,
        title: scenario.title,
        story: scenario.story,
        task: scenario.task,
        choices: scenario.choices
            .asMap()
            .entries
            .map((entry) => TeamScenarioChoiceModel(index: entry.key, text: entry.value.text))
            .toList(growable: false),
      ),
      rolePool: result.roles
          .map((item) => TeamRoleOptionModel(
                id: item.role.id,
                name: item.role.name,
                iconKey: item.role.iconKey,
                description: item.role.description,
              ))
          .toList(growable: false),
      participants: <TeamParticipantModel>[
        TeamParticipantModel(
          userId: userId,
          displayName: displayName,
          isHost: true,
          joinedAt: now,
          lastActiveAt: now,
        ),
      ],
      turn: TeamTurnModel(maxRounds: max(1, min(maxRounds, 5))),
      createdAt: now,
      updatedAt: now,
      expiresAt: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    );
    sessions[roomCode] = session;
    await _saveLocalSessions(sessions);
    return session;
  }

  (RoleScenarioModel, ScenarioModel) _pickScenario(
    List<RoleScenarioModel> roles, {
    String? roleId,
    String? chapterId,
  }) {
    for (final roleScenario in roles) {
      for (final chapter in roleScenario.chapters) {
        if (chapterId != null && chapter.id == chapterId) return (roleScenario, chapter);
      }
    }
    if (roleId != null) {
      for (final roleScenario in roles) {
        if (roleScenario.role.id == roleId && roleScenario.chapters.isNotEmpty) {
          return (roleScenario, roleScenario.chapters.first);
        }
      }
    }
    final fallbackRole = roles.firstWhere((item) => item.chapters.isNotEmpty, orElse: () => roles.first);
    return (fallbackRole, fallbackRole.chapters.first);
  }

  TeamSessionModel _withParticipant(TeamSessionModel session, {required String userId, required String displayName}) {
    final now = DateTime.now().toIso8601String();
    final participants = <TeamParticipantModel>[];
    var found = false;
    for (final participant in session.participants) {
      if (participant.userId == userId) {
        found = true;
        participants.add(TeamParticipantModel(
          userId: participant.userId,
          displayName: displayName,
          selectedRoleId: participant.selectedRoleId,
          isHost: participant.isHost,
          joinedAt: participant.joinedAt,
          lastActiveAt: now,
        ));
      } else {
        participants.add(participant);
      }
    }
    if (!found) {
      participants.add(TeamParticipantModel(
        userId: userId,
        displayName: displayName,
        joinedAt: now,
        lastActiveAt: now,
      ));
    }
    return _copySession(session, participants: participants);
  }

  Future<TeamSessionModel> _submitLocalDecision({
    required String sessionId,
    required String userId,
    required int choiceIndex,
    String? roomCode,
  }) async {
    final sessions = await _loadLocalSessions();
    var session = _findLocalSession(sessions, sessionId: sessionId, roomCode: roomCode);
    if (session == null) throw const TeamSessionException('Team session not found.');
    if (session.isLobby) {
      session = await startSession(sessionId: sessionId, userId: userId, roomCode: roomCode);
    }
    if (!session.isCurrentTurn(userId)) throw const TeamSessionException('It is not your turn yet.');
    final scenarioPair = await _findLocalScenario(session.scenario.chapterId);
    final scenario = scenarioPair.$2;
    if (choiceIndex < 0 || choiceIndex >= scenario.choices.length) {
      throw const TeamSessionException('Invalid choice selected.');
    }
    final participant = session.participantByUserId(userId)!;
    final choice = scenario.choices[choiceIndex];
    final decision = _decisionFromChoice(
      session: session,
      participant: participant,
      choice: choice,
      choiceIndex: choiceIndex,
    );
    final decisions = <TeamDecisionModel>[...session.decisions, decision];
    final selected = session.participants.where((participant) => participant.hasSelectedRole).toList(growable: false);
    var nextTurnIndex = session.turn.currentTurnIndex + 1;
    var nextRound = session.turn.roundIndex;
    if (nextTurnIndex >= selected.length) {
      nextTurnIndex = 0;
      nextRound += 1;
    }
    final score = _localScore(decisions, selected.length);
    final completed = nextRound >= session.turn.maxRounds;
    final updated = _copySession(
      session,
      status: completed ? 'completed' : 'in_progress',
      decisions: decisions,
      teamScore: score,
      turn: TeamTurnModel(
        currentParticipantId: completed ? '' : selected[nextTurnIndex].userId,
        currentTurnIndex: nextTurnIndex,
        roundIndex: nextRound,
        maxRounds: session.turn.maxRounds,
        status: completed ? 'completed' : 'active',
        startedAt: DateTime.now().toIso8601String(),
      ),
      debrief: completed ? _localDebrief(score, decisions) : null,
    );
    sessions[updated.roomCode] = updated;
    await _saveLocalSessions(sessions);
    return updated;
  }

  Future<(RoleScenarioModel, ScenarioModel)> _findLocalScenario(String chapterId) async {
    final result = await ScenarioService.instance.loadScenarios(preferApi: false);
    for (final roleScenario in result.roles) {
      for (final scenario in roleScenario.chapters) {
        if (scenario.id == chapterId) return (roleScenario, scenario);
      }
    }
    throw const TeamSessionException('Scenario chapter not found.');
  }

  TeamDecisionModel _decisionFromChoice({
    required TeamSessionModel session,
    required TeamParticipantModel participant,
    required ChoiceModel choice,
    required int choiceIndex,
  }) {
    final now = DateTime.now().toIso8601String();
    final affectedRoles = session.participants
        .where((item) => item.userId != participant.userId && item.selectedRoleId.isNotEmpty)
        .map((item) => item.selectedRoleId)
        .toSet()
        .toList(growable: false);
    return TeamDecisionModel(
      id: 'local_decision_${DateTime.now().microsecondsSinceEpoch}',
      roundIndex: session.turn.roundIndex,
      turnIndex: session.turn.currentTurnIndex,
      userId: participant.userId,
      displayName: participant.displayName,
      roleId: participant.selectedRoleId,
      choiceIndex: choiceIndex,
      choiceText: choice.text,
      outcomeTitle: choice.outcome.title,
      outcomeSummary: choice.outcome.description,
      affectedRoles: affectedRoles,
      setFlags: choice.outcome.setFlags,
      clearFlags: choice.outcome.clearFlags,
      createdAt: now,
    );
  }

  TeamScoreModel _localScore(List<TeamDecisionModel> decisions, int selectedParticipantCount) {
    final collaboration = min(100, selectedParticipantCount * 18 + decisions.length * 8);
    var communication = 0;
    var accuracy = 0;
    var ethics = 0;
    for (final decision in decisions) {
      communication += decision.affectedRoles.isNotEmpty ? 16 : 8;
      accuracy += decision.outcomeSummary.isNotEmpty ? 14 : 8;
      ethics += decision.setFlags.any((flag) => flag.toLowerCase().contains('ethic') || flag.toLowerCase().contains('safe')) ? 18 : 12;
    }
    final count = max(1, decisions.length);
    return TeamScoreModel(
      collaboration: collaboration,
      communication: min(100, (communication / count).round()),
      speed: 100,
      accuracy: min(100, (accuracy / count).round()),
      ethics: min(100, (ethics / count).round()),
    );
  }

  TeamDebriefModel _localDebrief(TeamScoreModel score, List<TeamDecisionModel> decisions) {
    return TeamDebriefModel(
      appearedAt: DateTime.now().toIso8601String(),
      total: score.total,
      summary: 'The team completed the local turn-based simulation.',
      scoreBreakdown: score,
      keyMoments: decisions
          .map((decision) => <String, dynamic>{
                'displayName': decision.displayName,
                'roleId': decision.roleId,
                'choiceText': decision.choiceText,
                'affectedRoles': decision.affectedRoles,
                'outcomeSummary': decision.outcomeSummary,
              })
          .toList(growable: false),
      recommendations: const <String>[
        'Use the Node.js backend API for cross-device rooms.',
        'Replay with more roles to test cross-role consequences.',
      ],
    );
  }

  TeamSessionModel? _findLocalSession(Map<String, TeamSessionModel> sessions, {required String sessionId, String? roomCode}) {
    if (roomCode != null && sessions.containsKey(roomCode)) return sessions[roomCode];
    for (final session in sessions.values) {
      if (session.id == sessionId) return session;
    }
    return null;
  }

  TeamSessionModel _copySession(
    TeamSessionModel session, {
    String? status,
    List<TeamParticipantModel>? participants,
    Map<String, String>? selectedRoles,
    TeamTurnModel? turn,
    List<TeamDecisionModel>? decisions,
    TeamScoreModel? teamScore,
    TeamDebriefModel? debrief,
  }) {
    return TeamSessionModel(
      id: session.id,
      roomCode: session.roomCode,
      joinLink: session.joinLink,
      title: session.title,
      mode: session.mode,
      status: status ?? session.status,
      hostUserId: session.hostUserId,
      scenario: session.scenario,
      rolePool: session.rolePool,
      participants: participants ?? session.participants,
      selectedRoles: selectedRoles ?? session.selectedRoles,
      turn: turn ?? session.turn,
      decisions: decisions ?? session.decisions,
      teamFlags: session.teamFlags,
      roleImpacts: session.roleImpacts,
      teamScore: teamScore ?? session.teamScore,
      debrief: debrief ?? session.debrief,
      createdAt: session.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      expiresAt: session.expiresAt,
    );
  }

  Future<Map<String, TeamSessionModel>> _loadLocalSessions() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_localSessionsKey);
    if (raw == null || raw.trim().isEmpty) return <String, TeamSessionModel>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, TeamSessionModel>{};
    final output = <String, TeamSessionModel>{};
    decoded.forEach((key, value) {
      if (key is String && value is Map<String, dynamic>) {
        output[key] = TeamSessionModel.fromJson(value);
      }
    });
    return output;
  }

  Future<void> _saveLocalSessions(Map<String, TeamSessionModel> sessions) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = sessions.map((key, value) => MapEntry(key, _sessionToJson(value)));
    await preferences.setString(_localSessionsKey, jsonEncode(encoded));
  }

  Map<String, dynamic> _sessionToJson(TeamSessionModel session) => <String, dynamic>{
        'id': session.id,
        'roomCode': session.roomCode,
        'joinLink': session.joinLink,
        'title': session.title,
        'mode': session.mode,
        'status': session.status,
        'hostUserId': session.hostUserId,
        'scenario': session.scenario.toJson(),
        'rolePool': session.rolePool.map((role) => role.toJson()).toList(growable: false),
        'participants': session.participants.map((participant) => participant.toJson()).toList(growable: false),
        'selectedRoles': session.selectedRoles,
        'turn': session.turn.toJson(),
        'decisions': session.decisions
            .map((decision) => <String, dynamic>{
                  'id': decision.id,
                  'roundIndex': decision.roundIndex,
                  'turnIndex': decision.turnIndex,
                  'userId': decision.userId,
                  'displayName': decision.displayName,
                  'roleId': decision.roleId,
                  'choiceIndex': decision.choiceIndex,
                  'choiceText': decision.choiceText,
                  'outcomeTitle': decision.outcomeTitle,
                  'outcomeSummary': decision.outcomeSummary,
                  'affectedRoles': decision.affectedRoles,
                  'setFlags': decision.setFlags,
                  'clearFlags': decision.clearFlags,
                  'createdAt': decision.createdAt,
                  'elapsedSeconds': decision.elapsedSeconds,
                })
            .toList(growable: false),
        'teamFlags': session.teamFlags,
        'roleImpacts': session.roleImpacts,
        'teamScore': session.teamScore.toJson(),
        'debrief': session.debrief == null
            ? null
            : <String, dynamic>{
                'appearedAt': session.debrief!.appearedAt,
                'total': session.debrief!.total,
                'summary': session.debrief!.summary,
                'scoreBreakdown': session.debrief!.scoreBreakdown.toJson(),
                'keyMoments': session.debrief!.keyMoments,
                'roleImpacts': session.debrief!.roleImpacts,
                'teamFlags': session.debrief!.teamFlags,
                'recommendations': session.debrief!.recommendations,
              },
        'createdAt': session.createdAt,
        'updatedAt': session.updatedAt,
        'expiresAt': session.expiresAt,
      };

  String _roomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List<String>.generate(6, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }
}

class TeamSessionException implements Exception {
  final String message;
  const TeamSessionException(this.message);

  @override
  String toString() => message;
}
