import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/team_session_model.dart';

void main() {
  test('team session parses room, participants, roles, score, and debrief', () {
    final session = TeamSessionModel.fromJson(jsonDecode('''
    {
      "id":"session-1",
      "roomCode":"ABC123",
      "joinLink":"/team/join/ABC123",
      "title":"Team Room",
      "status":"completed",
      "hostUserId":"u1",
      "scenario":{"roleId":"developer","chapterId":"c1","title":"Release Fire Drill","story":"Prod issue","task":"Choose","choices":[{"index":0,"text":"Coordinate rollback"}]},
      "rolePool":[{"id":"developer","name":"Developer"},{"id":"qa","name":"QA"}],
      "participants":[{"userId":"u1","displayName":"Aman","selectedRoleId":"developer","isHost":true},{"userId":"u2","displayName":"Friend","selectedRoleId":"qa"}],
      "selectedRoles":{"u1":"developer","u2":"qa"},
      "turn":{"currentParticipantId":"","currentTurnIndex":0,"roundIndex":1,"maxRounds":1,"status":"completed"},
      "decisions":[{"id":"d1","userId":"u1","displayName":"Aman","roleId":"developer","choiceIndex":0,"choiceText":"Coordinate rollback","outcomeTitle":"Safe","outcomeSummary":"QA is notified.","affectedRoles":["qa"],"setFlags":["team_aligned"]}],
      "teamFlags":["team_aligned"],
      "roleImpacts":{"qa":["Developer chose rollback"]},
      "teamScore":{"collaboration":80,"communication":75,"speed":90,"accuracy":70,"ethics":85},
      "debrief":{"total":80,"summary":"Strong run","scoreBreakdown":{"collaboration":80,"communication":75,"speed":90,"accuracy":70,"ethics":85},"recommendations":["Replay with more roles."]}
    }
    ''') as Map<String, dynamic>);

    expect(session.roomCode, 'ABC123');
    expect(session.isCompleted, isTrue);
    expect(session.participants.length, 2);
    expect(session.selectedRoleIds.contains('qa'), isTrue);
    expect(session.decisions.single.affectedRoles, contains('qa'));
    expect(session.teamScore.total, 80);
    expect(session.debrief?.recommendations.single, 'Replay with more roles.');
  });

  test('current turn and role locking helpers work', () {
    final session = TeamSessionModel.fromJson({
      'id': 'session-2',
      'roomCode': 'ROOM22',
      'status': 'in_progress',
      'participants': [
        {'userId': 'u1', 'displayName': 'Host', 'selectedRoleId': 'developer'},
        {'userId': 'u2', 'displayName': 'QA', 'selectedRoleId': 'qa'},
      ],
      'turn': {'currentParticipantId': 'u2', 'status': 'active'},
      'teamScore': {'collaboration': 50, 'communication': 50, 'speed': 100, 'accuracy': 50, 'ethics': 50},
    });

    expect(session.isCurrentTurn('u2'), isTrue);
    expect(session.isCurrentTurn('u1'), isFalse);
    expect(session.isRoleTakenByOther('qa', 'u1'), isTrue);
    expect(session.participantByUserId('u2')?.displayName, 'QA');
  });
}
