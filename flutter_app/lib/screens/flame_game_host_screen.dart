import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../games/base_mini_game.dart';
import '../games/flame_mini_game_factory.dart';
import '../games/hub_world_game.dart';
import '../models/flame_mini_game_model.dart';
import '../services/animation_service.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';
import '../widgets/info_panel.dart';
import '../widgets/motion_feedback_animation.dart';

typedef FlameHubContentBuilder = Widget Function(
  BuildContext context,
  HubWorldLocationKind location,
);

class FlameGameHostScreen extends StatefulWidget {
  final FlameMiniGameKind? initialKind;
  final bool chapterMode;
  final FlameHubContentBuilder? hubContentBuilder;
  final String? hubTitle;

  const FlameGameHostScreen({
    super.key,
    this.initialKind,
    this.chapterMode = false,
    this.hubContentBuilder,
    this.hubTitle,
  }) : assert(
          hubContentBuilder == null || initialKind == null,
          'Hub mode and direct mini-game mode are mutually exclusive.',
        );

  bool get isHubMode => hubContentBuilder != null;

  @override
  State<FlameGameHostScreen> createState() => _FlameGameHostScreenState();
}

class _FlameGameHostScreenState extends State<FlameGameHostScreen> {
  BaseMiniGame? _game;
  FlameMiniGameKind? _kind;
  FlameMiniGameResultModel? _lastResult;
  HubWorldGame? _hubGame;
  bool _hubOverlayOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.isHubMode) {
      _hubGame = HubWorldGame(
        onLocationSelected: _openHubLocation,
        reducedMotion: AnimationService.instance.isReducedMotion,
      );
      AnimationService.instance.reducedMotion.addListener(
        _handleReducedMotionChanged,
      );
      unawaited(_startHubAudio());
      return;
    }

    final initialKind = widget.initialKind;
    if (initialKind != null) {
      _startGame(initialKind);
    }
  }

  @override
  void dispose() {
    _game?.disposeNotifiers();
    if (widget.isHubMode) {
      AnimationService.instance.reducedMotion.removeListener(
        _handleReducedMotionChanged,
      );
      _hubGame?.disposeNotifiers();
      unawaited(AudioService.instance.stopBackgroundMusic());
    }
    super.dispose();
  }

  void _handleReducedMotionChanged() {
    _hubGame?.setReducedMotion(AnimationService.instance.isReducedMotion);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startHubAudio() {
    if (!widget.isHubMode || _hubOverlayOpen) {
      return Future<void>.value();
    }
    return AudioService.instance.playBackgroundMusic(
      'bgm_office_light',
      loop: true,
      volumeOverride: 0.28,
    );
  }

  Future<void> _openHubLocation(HubWorldLocationKind location) async {
    final builder = widget.hubContentBuilder;
    if (builder == null || _hubOverlayOpen || !mounted) {
      return;
    }

    setState(() => _hubOverlayOpen = true);
    await AudioService.instance.stopBackgroundMusic();

    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.64),
        transitionDuration: AnimationService.instance.duration(
          const Duration(milliseconds: 260),
        ),
        pageBuilder: (dialogContext, _, __) {
          return SafeArea(
            child: Material(
              color: const Color(0xFF070913),
              child: builder(dialogContext, location),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          if (AnimationService.instance.isReducedMotion) {
            return child;
          }
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
    } finally {
      _hubGame?.markHubReady();
      if (mounted) {
        setState(() => _hubOverlayOpen = false);
        unawaited(_startHubAudio());
      }
    }
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
          title: Text(game.resultDialogTitle(result)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.message),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: game
                    .resultSummaryLabels(result)
                    .map((label) => _ResultChip(label: label))
                    .toList(growable: false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startGame(result.kind);
              },
              child: Text(game.retryActionLabel),
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
    if (widget.isHubMode) {
      return _buildHubWorld(context);
    }

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

  Widget _buildHubWorld(BuildContext context) {
    final game = _hubGame;
    if (game == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF070913),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070913),
      appBar: AppBar(
        title: Text(widget.hubTitle ?? 'Developer Hub'),
        backgroundColor: const Color(0xFF070913),
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: AnimationService.instance.reducedMotion,
            builder: (context, reducedMotion, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: reducedMotion
                      ? 'Reduced motion enabled'
                      : 'Hub movement enabled',
                  child: Icon(
                    reducedMotion
                        ? Icons.motion_photos_off_rounded
                        : Icons.directions_walk_rounded,
                    color: Colors.white70,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => unawaited(_startHubAudio()),
                child: GameWidget<HubWorldGame>(game: game),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: IgnorePointer(
                child: ValueListenableBuilder<String>(
                  valueListenable: game.statusMessage,
                  builder: (context, status, _) {
                    final message = _hubOverlayOpen
                        ? 'Mission active • the hub stays loaded underneath.'
                        : status;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFF0C0E18).withValues(alpha: 0.88),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            game.isWalking
                                ? Icons.directions_walk_rounded
                                : Icons.touch_app_rounded,
                            color: const Color(0xFFFF80AD),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
            'Run interactive Flame challenges. Developer sessions can now rotate between different live gameplay systems, while every result still saves XP and score impact.',
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
                  color: const Color(0xFFFF4D8D).withValues(alpha: 0.16),
                  border: Border.all(
                    color: const Color(0xFFFF4D8D).withValues(alpha: 0.44),
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D8D).withValues(alpha: 0.18),
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
                  color: Colors.white.withValues(alpha: 0.07),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
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
                      game.progressSummary(selected),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (game.allowClearSelection)
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
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _finishGame,
                  icon: const Icon(Icons.shield),
                  label: Text(game.submitActionLabel),
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
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(0xFFFF4D8D).withValues(alpha: 0.18),
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
