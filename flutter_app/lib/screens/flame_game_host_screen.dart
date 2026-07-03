import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../games/base_mini_game.dart';
import '../games/flame_mini_game_factory.dart';
import '../models/flame_mini_game_model.dart';
import '../services/progress_service.dart';
import '../widgets/info_panel.dart';
import '../widgets/motion_feedback_animation.dart';

class FlameGameHostScreen extends StatefulWidget {
  final FlameMiniGameKind? initialKind;
  final bool chapterMode;

  const FlameGameHostScreen({
    super.key,
    this.initialKind,
    this.chapterMode = false,
  });

  @override
  State<FlameGameHostScreen> createState() => _FlameGameHostScreenState();
}

class _FlameGameHostScreenState extends State<FlameGameHostScreen> {
  BaseMiniGame? _game;
  FlameMiniGameKind? _kind;
  FlameMiniGameResultModel? _lastResult;

  @override
  void initState() {
    super.initState();
    final initialKind = widget.initialKind;
    if (initialKind != null) {
      _startGame(initialKind);
    }
  }

  @override
  void dispose() {
    _game?.disposeNotifiers();
    super.dispose();
  }

  void _startGame(FlameMiniGameKind kind) {
    _game?.disposeNotifiers();
    setState(() {
      _kind = kind;
      _game = FlameMiniGameFactory.create(kind);
      _lastResult = null;
    });
  }

  Future<void> _finishGame() async {
    final game = _game;
    if (game == null) {
      return;
    }

    final result = game.finish();
    await ProgressService.instance.recordFlameMiniGameResult(result);

    if (!mounted) {
      return;
    }

    setState(() => _lastResult = result);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: MotionFeedbackAnimation(
            type: result.isSuccess
                ? MotionFeedbackType.success
                : MotionFeedbackType.failure,
            size: 104,
          ),
          title: Text(
            result.isSuccess ? 'Incident contained!' : 'Chaos report generated',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ResultChip(label: 'XP +${result.xpEarned}'),
                  _ResultChip(label: 'Correct ${result.correctCount}'),
                  _ResultChip(label: 'Wrong ${result.wrongCount}'),
                  _ResultChip(label: '${result.elapsedSeconds}s'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startGame(result.kind);
              },
              child: const Text('Retry'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(this.context).pop(result);
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(widget.chapterMode ? 'Continue Story' : 'Back to App'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      backgroundColor: const Color(0xFF070913),
      appBar: AppBar(
        title: Text(widget.chapterMode ? 'Chapter Challenge' : 'Flame Game Lab'),
        backgroundColor: const Color(0xFF070913),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: game == null ? _buildGamePicker(context) : _buildGame(context, game),
      ),
    );
  }

  Widget _buildGamePicker(BuildContext context) {
    return ResponsiveContent(
      child: ListView(
        padding: ResponsiveLayout.pagePadding(context),
        children: [
          Text(
            'Choose a live simulation',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap targets directly inside the Flame arena. Every challenge saves XP and score impact.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 18),
          ...FlameMiniGameFactory.definitions.map(
            (definition) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GameMissionCard(
                definition: definition,
                icon: _iconFor(definition.kind),
                onTap: () => _startGame(definition.kind),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame(BuildContext context, BaseMiniGame game) {
    final definition = game.definition;
    final arenaHeight = MediaQuery.sizeOf(context).height < 720 ? 380.0 : 480.0;

    return ResponsiveContent(
      maxWidth: 920,
      child: ListView(
        padding: ResponsiveLayout.pagePadding(context).copyWith(top: 10),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFFF4D8D).withOpacity(0.16),
                  border: Border.all(
                    color: const Color(0xFFFF4D8D).withOpacity(0.44),
                  ),
                ),
                child: Icon(
                  _iconFor(definition.kind),
                  color: const Color(0xFFFF7AAA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      definition.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: arenaHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D8D).withOpacity(0.18),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: GameWidget<BaseMiniGame>(game: game),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: game.feedbackMessage,
            builder: (context, feedback, _) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radar, color: Color(0xFF70D6FF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feedback,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: game.comboCount,
                      builder: (context, combo, _) {
                        if (combo < 2) {
                          return const SizedBox.shrink();
                        }
                        return Chip(label: Text('${combo}x COMBO'));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<Set<String>>(
            valueListenable: game.selectedTargetIds,
            builder: (context, selected, _) {
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      '${selected.length} selected • ${definition.successThreshold} correct targets required',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: selected.isEmpty ? null : game.clearSelection,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _startGame(_kind ?? FlameMiniGameKind.bugHuntRoom),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.24)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _finishGame,
                  icon: const Icon(Icons.shield),
                  label: const Text('Submit Investigation'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D8D),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (_lastResult != null) ...[
            const SizedBox(height: 12),
            InfoPanel(
              title: _lastResult!.isSuccess ? 'Last success' : 'Last failure',
              body:
                  '${_lastResult!.message}\nXP +${_lastResult!.xpEarned} • Score ${_lastResult!.scoreImpact.total}',
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(FlameMiniGameKind kind) {
    switch (kind) {
      case FlameMiniGameKind.bugHuntRoom:
        return Icons.bug_report;
      case FlameMiniGameKind.dataCleanupRace:
        return Icons.table_chart;
      case FlameMiniGameKind.blueprintSafetyPuzzle:
        return Icons.architecture;
    }
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}

class _GameMissionCard extends StatelessWidget {
  const _GameMissionCard({
    required this.definition,
    required this.icon,
    required this.onTap,
  });

  final FlameMiniGameDefinitionModel definition;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFF4D8D).withOpacity(0.18),
                foregroundColor: const Color(0xFFFF7AAA),
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${definition.subtitle}\n${definition.timeLimitSeconds}s • ${definition.successXp} XP',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
