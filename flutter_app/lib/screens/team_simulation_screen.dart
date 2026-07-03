import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../models/team_session_model.dart';
import '../services/animation_service.dart';
import '../services/device_user_service.dart';
import '../services/team_session_service.dart';
import 'team_debrief_screen.dart';

class TeamSimulationScreen extends StatefulWidget {
  const TeamSimulationScreen({super.key});

  @override
  State<TeamSimulationScreen> createState() => _TeamSimulationScreenState();
}

class _TeamSimulationScreenState extends State<TeamSimulationScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Player');
  final TextEditingController _joinCodeController = TextEditingController();
  TeamSessionModel? _session;
  String _userId = '';
  bool _isLoading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    if (!mounted) return;
    setState(() {
      _userId = userId;
      _isLoading = false;
    });
  }

  Future<void> _run(Future<TeamSessionModel> Function() action) async {
    setState(() {
      _isLoading = true;
      _message = '';
    });
    try {
      final session = await action();
      if (!mounted) return;
      setState(() {
        _session = session;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _createRoom() async {
    await _run(() => TeamSessionService.instance.createRoom(
          userId: _userId,
          displayName: _displayName,
          title: 'Career Chaos Team Room',
        ));
  }

  Future<void> _joinRoom() async {
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _message = 'Enter a room code or link first.');
      return;
    }
    final normalized = code.split('/').last.trim().toUpperCase();
    await _run(() => TeamSessionService.instance.joinByCode(
          roomCode: normalized,
          userId: _userId,
          displayName: _displayName,
        ));
  }

  Future<void> _selectRole(String roleId) async {
    final session = _session;
    if (session == null) return;
    await _run(() => TeamSessionService.instance.selectRole(
          sessionId: session.id,
          userId: _userId,
          roleId: roleId,
          roomCode: session.roomCode,
        ));
  }

  Future<void> _startSession() async {
    final session = _session;
    if (session == null) return;
    await _run(() => TeamSessionService.instance.startSession(
          sessionId: session.id,
          userId: _userId,
          roomCode: session.roomCode,
        ));
  }

  Future<void> _refreshSession() async {
    final session = _session;
    if (session == null) return;
    await _run(() => TeamSessionService.instance.getSession(session.id, roomCode: session.roomCode));
  }

  Future<void> _submitDecision(int choiceIndex) async {
    final session = _session;
    if (session == null) return;
    await _run(() => TeamSessionService.instance.submitDecision(
          sessionId: session.id,
          userId: _userId,
          choiceIndex: choiceIndex,
          roomCode: session.roomCode,
        ));
  }

  void _openDebrief() {
    final session = _session;
    if (session == null) return;
    Navigator.of(context).push(
      AnimationService.instance.motionRoute<void>(
        settings: const RouteSettings(name: AppRoutes.teamDebrief),
        builder: (_) => TeamDebriefScreen(session: session),
      ),
    );
  }

  String get _displayName {
    final value = _nameController.text.trim();
    return value.isEmpty ? 'Player' : value;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Simulation'),
        actions: [
          if (session != null)
            IconButton(
              tooltip: 'Refresh room',
              onPressed: _isLoading ? null : _refreshSession,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(18),
              children: [
                _HeaderCard(
                  roomCode: session?.roomCode,
                  joinLink: session?.joinLink,
                  status: session?.status,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your display name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (session == null) _CreateJoinCard(onCreate: _createRoom, onJoin: _joinRoom, controller: _joinCodeController),
                if (session != null) ...[
                  _RoomCard(session: session, currentUserId: _userId),
                  const SizedBox(height: 12),
                  _RoleSelectionCard(
                    session: session,
                    currentUserId: _userId,
                    onSelectRole: _selectRole,
                  ),
                  const SizedBox(height: 12),
                  if (session.isLobby)
                    FilledButton.icon(
                      onPressed: session.hasSelectedParticipants && !_isLoading ? _startSession : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Turn-Based Scenario'),
                    ),
                  if (session.isInProgress) _ScenarioTurnCard(session: session, currentUserId: _userId, onChoose: _submitDecision),
                  if (session.isCompleted) _CompletedCard(session: session, onOpenDebrief: _openDebrief),
                  const SizedBox(height: 12),
                  _TeamScoreCard(score: session.teamScore),
                ],
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(_message),
                    ),
                  ),
                ],
              ],
            ),
            if (_isLoading)
              Container(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String? roomCode;
  final String? joinLink;
  final String? status;

  const _HeaderCard({this.roomCode, this.joinLink, this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multiplayer Role-Based Team Simulation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text('Create a room, invite teammates, select different roles, and solve a shared career chaos scenario turn by turn.'),
          if (roomCode != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Code: $roomCode')),
                Chip(label: Text('Status: ${status ?? 'lobby'}')),
                if (joinLink != null && joinLink!.isNotEmpty) Chip(label: Text(joinLink!)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateJoinCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final TextEditingController controller;

  const _CreateJoinCard({required this.onCreate, required this.onJoin, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_circle),
              label: const Text('Create Team Room'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Join by code/link',
                hintText: 'Example: ABC123 or /team/join/ABC123',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.login),
              label: const Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final TeamSessionModel session;
  final String currentUserId;

  const _RoomCard({required this.session, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room Participants', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final participant in session.participants)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(participant.userId == currentUserId ? Icons.person_pin_circle : Icons.person),
                title: Text('${participant.displayName}${participant.isHost ? ' • Host' : ''}'),
                subtitle: Text(participant.selectedRoleId.isEmpty ? 'No role selected yet' : 'Role: ${participant.selectedRoleId}'),
                trailing: session.turn.currentParticipantId == participant.userId ? const Chip(label: Text('Turn')) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final TeamSessionModel session;
  final String currentUserId;
  final ValueChanged<String> onSelectRole;

  const _RoleSelectionCard({required this.session, required this.currentUserId, required this.onSelectRole});

  @override
  Widget build(BuildContext context) {
    final currentParticipant = session.participantByUserId(currentUserId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Your Role', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(session.isLobby ? 'Each teammate should select a unique role.' : 'Roles are locked after the scenario starts.'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in session.rolePool)
                  ChoiceChip(
                    label: Text(role.name),
                    selected: currentParticipant?.selectedRoleId == role.id,
                    onSelected: session.isLobby && !session.isRoleTakenByOther(role.id, currentUserId)
                        ? (_) => onSelectRole(role.id)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioTurnCard extends StatelessWidget {
  final TeamSessionModel session;
  final String currentUserId;
  final ValueChanged<int> onChoose;

  const _ScenarioTurnCard({required this.session, required this.currentUserId, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final isMyTurn = session.isCurrentTurn(currentUserId);
    final current = session.currentParticipant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.scenario.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(session.scenario.story),
            const SizedBox(height: 8),
            Text(session.scenario.task, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Chip(label: Text(isMyTurn ? 'Your turn' : 'Waiting for ${current?.displayName ?? 'teammate'}')),
            const SizedBox(height: 8),
            for (final choice in session.scenario.choices)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: isMyTurn ? () => onChoose(choice.index) : null,
                  child: Align(alignment: Alignment.centerLeft, child: Text(choice.text)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final TeamSessionModel session;
  final VoidCallback onOpenDebrief;

  const _CompletedCard({required this.session, required this.onOpenDebrief});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Simulation Complete', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(session.debrief?.summary ?? 'Open the debrief to review team consequences and score.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpenDebrief,
              icon: const Icon(Icons.insights),
              label: const Text('Open Team Debrief'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamScoreCard extends StatelessWidget {
  final TeamScoreModel score;

  const _TeamScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team Score', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            _ScoreLine(label: 'Collaboration', value: score.collaboration),
            _ScoreLine(label: 'Communication', value: score.communication),
            _ScoreLine(label: 'Speed', value: score.speed),
            _ScoreLine(label: 'Accuracy', value: score.accuracy),
            _ScoreLine(label: 'Ethics', value: score.ethics),
          ],
        ),
      ),
    );
  }
}

class _ScoreLine extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: LinearProgressIndicator(value: value.clamp(0, 100) / 100)),
          const SizedBox(width: 10),
          Text('$value'),
        ],
      ),
    );
  }
}
