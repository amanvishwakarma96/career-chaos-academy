import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../games/cinematic_atmosphere_game.dart';
import '../core/character_registry.dart';
import '../core/responsive_layout.dart';
import '../models/dialogue_line_model.dart';
import '../models/dialogue_scene_model.dart';
import '../models/flame_mini_game_model.dart';
import '../models/mini_game_progress_model.dart';
import '../models/mini_game_result_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../core/asset_registry.dart';
import '../services/asset_preload_service.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';
import '../services/story_continuity_service.dart';
import '../services/animation_service.dart';
import '../services/adaptive_story_service.dart';
import '../services/future_scope/feature_flag_service.dart';
import '../widgets/animated_character_portrait.dart';
import '../widgets/consequence_impact_dialog.dart';
import '../widgets/choice_button.dart';
import '../widgets/game_asset_image.dart';
import '../widgets/info_panel.dart';
import '../widgets/mini_game_status_card.dart';
import '../widgets/typing_text.dart';
import '../widgets/parallax_scene_background.dart';
import 'flame_game_host_screen.dart';
import 'mini_game_screen.dart';
import 'result_screen.dart';

class DialogueSceneScreen extends StatefulWidget {
  final RoleScenarioModel roleScenario;
  final ScenarioModel scenario;
  final int chapterIndex;

  const DialogueSceneScreen({
    super.key,
    required this.roleScenario,
    required this.scenario,
    required this.chapterIndex,
  });

  @override
  State<DialogueSceneScreen> createState() => _DialogueSceneScreenState();
}

class _DialogueSceneScreenState extends State<DialogueSceneScreen> {
  int _sceneIndex = 0;
  int _dialogueIndex = 0;
  bool _dialogueComplete = false;
  bool _autoPlay = false;
  bool _skipTyping = false;
  Timer? _autoPlayTimer;
  MiniGameResultModel? _currentMiniGameResult;
  bool _assetsReady = false;
  bool _assetsStarted = false;
  CharacterRegistry _characterRegistry = CharacterRegistry.empty;
  late final CinematicAtmosphereGame _atmosphereGame;

  ScenarioModel get scenario => widget.scenario;
  RoleScenarioModel get roleScenario => widget.roleScenario;
  int get chapterIndex => widget.chapterIndex;
  List<DialogueSceneModel> get scenes => scenario.scenes;
  bool get _hasScenes => scenes.isNotEmpty;
  bool get _visualOverhaulEnabled =>
      FeatureFlagService.instance.isEnabled('game_visual_overhaul');

  DialogueSceneModel get _currentScene {
    final index = _sceneIndex.clamp(0, scenes.length - 1).toInt();
    return scenes[index];
  }

  DialogueLineModel get _currentDialogue {
    final currentScene = _currentScene;
    final dialogues = _visibleDialoguesFor(currentScene);
    final index = _dialogueIndex
        .clamp(0, dialogues.length - 1)
        .toInt();
    return dialogues[index];
  }

  List<DialogueLineModel> _visibleDialoguesFor(DialogueSceneModel scene) {
    final roleId = roleScenario.role.id;
    final visible = StoryContinuityService.instance.visibleDialogues(
      scene: scene,
      storyFlags: ProgressService.instance.storyFlagsFor(roleId),
      relationship: ProgressService.instance.relationshipFor(roleId),
    );
    final baseDialogues = visible.isEmpty ? scene.dialogues : visible;
    final isFirstScene = scenes.isNotEmpty && scene.id == scenes.first.id;
    if (!isFirstScene || scenario.adaptiveDialogueInjections.isEmpty) {
      return baseDialogues;
    }
    final behaviorSummary = AdaptiveStoryService.instance.buildBehaviorSummary(
      roleScenarios: <RoleScenarioModel>[roleScenario],
    );
    final adaptiveLines = AdaptiveStoryService.instance.adaptiveDialogueForScenario(
      scenario: scenario,
      summary: behaviorSummary,
    );
    if (adaptiveLines.isEmpty) {
      return baseDialogues;
    }
    return <DialogueLineModel>[...adaptiveLines, ...baseDialogues];
  }

  MiniGameProgressModel? get _savedMiniGameProgress {
    final miniGame = scenario.miniGame;
    if (miniGame == null) {
      return null;
    }

    return ProgressService.instance.miniGameProgressFor(
      roleId: roleScenario.role.id,
      miniGameId: miniGame.id,
    );
  }

  bool get _canShowChoices {
    if (!_dialogueComplete) {
      return false;
    }
    if (scenario.miniGame == null) {
      return true;
    }
    return _currentMiniGameResult != null || _savedMiniGameProgress != null;
  }


  @override
  void initState() {
    super.initState();
    _atmosphereGame = CinematicAtmosphereGame();
  }

  void _syncAtmosphere() {
    if (!_hasScenes || _dialogueComplete) {
      return;
    }
    _atmosphereGame.updateMood(
      sceneKey: _currentScene.id,
      emotion: _currentDialogue.emotion,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsStarted) {
      _assetsStarted = true;
      _prepareAssets();
    }
  }

  Future<void> _prepareAssets() async {
    final characterRegistry = await CharacterRegistry.loadFromAssets();
    await AssetPreloadService.preloadScenarioAssets(
      context,
      scenario,
      characterRegistry: characterRegistry,
    );
    await AudioService.instance.preloadScenarioAudio(scenario);
    if (!mounted) {
      return;
    }
    setState(() {
      _characterRegistry = characterRegistry;
      _assetsReady = true;
    });
    _syncAtmosphere();
    _playCurrentSceneAudio();
    _playCurrentDialogueAudio();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    unawaited(AudioService.instance.stopSceneAudio());
    super.dispose();
  }

  void _playCurrentSceneAudio() {
    if (!_assetsReady || !_hasScenes || _dialogueComplete) {
      return;
    }
    unawaited(AudioService.instance.playSceneAudio(_currentScene));
  }

  void _playCurrentDialogueAudio() {
    if (!_assetsReady || !_hasScenes || _dialogueComplete) {
      return;
    }
    unawaited(AudioService.instance.playDialogueAudio(_currentDialogue));
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer?.cancel();
    if (!_autoPlay || _dialogueComplete) {
      return;
    }
    _autoPlayTimer = Timer(const Duration(milliseconds: 2200), _nextDialogue);
  }

  void _nextDialogue() {
    _autoPlayTimer?.cancel();
    if (!_hasScenes || _dialogueComplete) {
      return;
    }

    final currentScene = _currentScene;
    final visibleDialogues = _visibleDialoguesFor(currentScene);
    if (_dialogueIndex < visibleDialogues.length - 1) {
      setState(() {
        _dialogueIndex += 1;
        _skipTyping = false;
      });
      _syncAtmosphere();
      _playCurrentDialogueAudio();
      _scheduleAutoPlay();
      return;
    }

    if (_sceneIndex < scenes.length - 1) {
      setState(() {
        _sceneIndex += 1;
        _dialogueIndex = 0;
        _skipTyping = false;
      });
      _syncAtmosphere();
      _playCurrentSceneAudio();
      _playCurrentDialogueAudio();
      _scheduleAutoPlay();
      return;
    }

    setState(() {
      _dialogueComplete = true;
      _skipTyping = true;
    });
    unawaited(AudioService.instance.playSoundEffect('choice_select'));
  }

  void _skipDialogue() {
    _autoPlayTimer?.cancel();
    setState(() {
      _sceneIndex = scenes.length - 1;
      _dialogueIndex = _visibleDialoguesFor(scenes.last).length - 1;
      _dialogueComplete = true;
      _skipTyping = true;
    });
  }

  Future<void> _openMiniGame() async {
    final miniGame = scenario.miniGame;
    if (miniGame == null) {
      return;
    }

    await AudioService.instance.stopSceneAudio();

    MiniGameResultModel? result;
    final usePhase36FlameSlice = _visualOverhaulEnabled &&
        roleScenario.role.id == 'developer' &&
        chapterIndex == 0;

    if (usePhase36FlameSlice) {
      final flameResult = await Navigator.of(context)
          .push<FlameMiniGameResultModel>(
        AnimationService.instance.motionRoute<FlameMiniGameResultModel>(
          settings: const RouteSettings(name: AppRoutes.flameMiniGameHost),
          transition: MotionRouteTransition.slideUp,
          builder: (_) => const FlameGameHostScreen(
            initialKind: FlameMiniGameKind.bugHuntRoom,
            chapterMode: true,
          ),
        ),
      );
      if (flameResult != null) {
        result = MiniGameResultModel(
          miniGameId: miniGame.id,
          type: miniGame.type,
          isSuccess: flameResult.isSuccess,
          scoreImpact: flameResult.scoreImpact,
          message: flameResult.message,
          selectedOptionIds: flameResult.selectedTargetIds,
        );
      }
    } else {
      result = await Navigator.of(context).push<MiniGameResultModel>(
        AnimationService.instance.motionRoute<MiniGameResultModel>(
          settings: const RouteSettings(name: AppRoutes.miniGame),
          transition: MotionRouteTransition.slideUp,
          builder: (_) => MiniGameScreen(miniGame: miniGame),
        ),
      );
    }

    if (result == null) {
      return;
    }

    await ProgressService.instance.recordMiniGameResult(
      roleScenario: roleScenario,
      chapter: scenario,
      result: result,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentMiniGameResult = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? 'Mini-game passed. The dramatic choice moment is unlocked.'
              : 'Mini-game failed. The story continues, but consequences may follow.',
        ),
      ),
    );
  }

  Future<void> _completeChapterAndShowOutcome({
    required BuildContext context,
    required int choiceIndex,
  }) async {
    final choice = scenario.choices[choiceIndex];
    await AudioService.instance.playChoiceSelect();

    final progressUpdate = await ProgressService.instance.completeChapter(
      roleScenario: roleScenario,
      chapter: scenario,
      scoreImpact: choice.scoreImpact,
      outcome: choice.outcome,
    );

    if (!context.mounted) {
      return;
    }

    await AudioService.instance.stopSceneAudio();
    await AudioService.instance.playResultSfx(
      isSuccess: choice.scoreImpact.chaos <= 0,
    );
    if (progressUpdate.hasNewBadges || progressUpdate.didRankUp) {
      unawaited(AudioService.instance.playBadgeUnlock());
    }

    final consequence = choice.outcome.consequenceSummary.trim();
    await ConsequenceImpactDialog.show(
      context,
      title: choice.outcome.title,
      summary: consequence,
      scoreImpact: choice.scoreImpact,
      isPositive: choice.scoreImpact.chaos <= 0 && choice.scoreImpact.ethics >= 0,
    );

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).push(
      AnimationService.instance.motionRoute<void>(
        transition: MotionRouteTransition.fadeScale,
        builder: (_) => ResultScreen(
          scenario: scenario,
          choice: choice,
          isLastChapter:
              scenario.isFinale || chapterIndex >= roleScenario.totalChapters - 1,
          progressUpdate: progressUpdate,
          roleScenario: roleScenario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasScenes) {
      return _CinematicFallbackScenario(
        roleScenario: roleScenario,
        scenario: scenario,
        chapterIndex: chapterIndex,
      );
    }

    if (!_assetsReady) {
      return _CinematicLoadingScreen(scenario: scenario);
    }

    final scene = _currentScene;
    final dialogue = _currentDialogue;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${scenario.role.name} • Cinematic Chapter'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _autoPlay ? 'Stop auto-play' : 'Auto-play dialogue',
            onPressed: () {
              setState(() {
                _autoPlay = !_autoPlay;
              });
              _scheduleAutoPlay();
            },
            icon: Icon(_autoPlay ? Icons.pause_circle : Icons.play_circle),
          ),
          TextButton(
            onPressed: _skipDialogue,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _SceneBackground(scene: scene),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.08),
                  Colors.black.withOpacity(0.82),
                ],
              ),
            ),
          ),
          if (_visualOverhaulEnabled)
            IgnorePointer(
              child: GameWidget<CinematicAtmosphereGame>(
                game: _atmosphereGame,
              ),
            ),
          SafeArea(
            child: ResponsiveContent(
              child: Padding(
                padding: ResponsiveLayout.pagePadding(context),
                child: AnimatedSwitcher(
                  duration: AnimationService.instance.duration(
                    _transitionDuration(scene.transitionType),
                  ),
                  switchInCurve: AnimationService.instance.curve(Curves.easeOutCubic),
                  switchOutCurve: AnimationService.instance.curve(Curves.easeInCubic),
                  transitionBuilder: (child, animation) {
                    return _sceneTransition(
                      child: child,
                      animation: animation,
                      transitionType: scene.transitionType,
                    );
                  },
                  child: _dialogueComplete
                      ? _buildPostDialogueContent(context)
                      : _buildDialogueContent(context, scene, dialogue),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueContent(
    BuildContext context,
    DialogueSceneModel scene,
    DialogueLineModel dialogue,
  ) {
    final emotion = dialogue.emotion;
    final emotionColor = _emotionColor(context, emotion);
    final character = _characterRegistry.findForDialogue(
      characterId: dialogue.characterId ?? scene.characterId,
      speaker: dialogue.speaker,
    );
    final speakerName = character?.displayName ?? dialogue.speaker;
    final portrait = character?.expressionFor(emotion) ??
        dialogue.characterImage ??
        scene.characterImage;
    final archetype = character?.archetype ?? 'scene';
    final subtitle = dialogue.audio.subtitle ?? dialogue.subtitle ?? dialogue.text;

    return Column(
      key: ValueKey('${scene.id}-$_dialogueIndex'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 54),
        _CinematicHud(
          roleName: scenario.role.name,
          sceneTitle: scene.title,
          sceneProgress: (_sceneIndex + 1) / scenes.length,
          lineProgress: (_dialogueIndex + 1) / _visibleDialoguesFor(scene).length,
          emotion: emotion,
        ),
        const Spacer(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedCharacterPortrait(
              imageReference: portrait,
              speaker: speakerName,
              emotion: emotion,
              archetype: archetype,
              color: emotionColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DialogueBubble(
                speaker: speakerName,
                emotion: emotion,
                color: emotionColor,
                subtitle: subtitle,
                child: TypingText(
                  text: dialogue.text,
                  animate: !_skipTyping,
                  characterDelay: const Duration(milliseconds: 18),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              'Scene ${_sceneIndex + 1}/${scenes.length} • Line ${_dialogueIndex + 1}/${_visibleDialoguesFor(scene).length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _skipTyping = true;
                });
              },
              icon: const Icon(Icons.fast_forward),
              label: const Text('Reveal'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _nextDialogue,
              icon: const Icon(Icons.navigate_next),
              label: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostDialogueContent(BuildContext context) {
    final miniGame = scenario.miniGame;
    final isFlameVerticalSlice = _visualOverhaulEnabled &&
        roleScenario.role.id == 'developer' &&
        chapterIndex == 0;

    return ListView(
      key: const ValueKey('post-dialogue'),
      children: [
        const SizedBox(height: 72),
        _DramaticChoiceHeader(scenario: scenario),
        if (scenario.professionalLearningPoint.isNotEmpty) ...[
          const SizedBox(height: 12),
          InfoPanel(
            title: 'Professional Learning Point',
            body: scenario.professionalLearningPoint,
          ),
        ],
        if (scenario.safetyDisclaimer != null) ...[
          const SizedBox(height: 12),
          InfoPanel(title: 'Safety Note', body: scenario.safetyDisclaimer!),
        ],
        if (miniGame != null) ...[
          const SizedBox(height: 12),
          MiniGameStatusCard(
            savedProgress: _savedMiniGameProgress,
            currentResult: _currentMiniGameResult,
            onStartPressed: _openMiniGame,
            titleOverride:
                isFlameVerticalSlice ? 'Live Bug Hunt challenge' : null,
            descriptionOverride: isFlameVerticalSlice
                ? 'Enter the Flame incident room and tap only the real production blockers before the timer expires.'
                : null,
            buttonLabel:
                isFlameVerticalSlice ? 'Enter Bug Hunt Room' : 'Start Mini-game',
          ),
        ],
        const SizedBox(height: 18),
        Text(
          _canShowChoices
              ? 'The room goes silent. Choose carefully.'
              : 'The story waits for your mini-game result.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        if (_canShowChoices)
          ...scenario.choices.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChoiceButton(
                    choice: entry.value,
                    choiceNumber: entry.key + 1,
                    onPressed: () => _completeChapterAndShowOutcome(
                      context: context,
                      choiceIndex: entry.key,
                    ),
                  ),
                ),
              )
        else
          const InfoPanel(
            title: 'Challenge gate',
            body:
                'Complete the mini-game first. Passing improves rewards; failure can still continue the story with consequences.',
          ),
      ],
    );
  }
}


class _CinematicHud extends StatelessWidget {
  const _CinematicHud({
    required this.roleName,
    required this.sceneTitle,
    required this.sceneProgress,
    required this.lineProgress,
    required this.emotion,
  });

  final String roleName;
  final String sceneTitle;
  final double sceneProgress;
  final double lineProgress;
  final String emotion;

  @override
  Widget build(BuildContext context) {
    final accent = _emotionColor(context, emotion);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.48),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(color: accent, blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE SCENARIO',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
              ),
              const Spacer(),
              Text(
                roleName.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  sceneTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                emotion.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (sceneProgress * 0.72 + lineProgress * 0.28)
                    .clamp(0.0, 1.0)
                    .toDouble(),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.68), accent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _CinematicLoadingScreen extends StatelessWidget {
  final ScenarioModel scenario;

  const _CinematicLoadingScreen({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator.adaptive(),
                  const SizedBox(height: 16),
                  Text(
                    'Preparing cinematic scene...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scenario.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SceneBackground extends StatelessWidget {
  final DialogueSceneModel scene;

  const _SceneBackground({required this.scene});

  @override
  Widget build(BuildContext context) {
    final image = scene.backgroundImage;
    if (image == null) {
      return _FallbackBackground(scene: scene);
    }

    return ParallaxSceneBackground(
      reference: image,
      type: GameAssetType.background,
      fallbackBuilder: (_, __) => _FallbackBackground(scene: scene),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  final DialogueSceneModel scene;

  const _FallbackBackground({required this.scene});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _transitionIcon(scene.transitionType),
          color: Colors.white.withOpacity(0.12),
          size: 180,
        ),
      ),
    );
  }
}

class _DialogueBubble extends StatelessWidget {
  final String speaker;
  final String emotion;
  final Color color;
  final String? subtitle;
  final Widget child;

  const _DialogueBubble({
    required this.speaker,
    required this.emotion,
    required this.color,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.82), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(_emotionIcon(emotion), color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                speaker,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              Text(
                emotion.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DramaticChoiceHeader extends StatelessWidget {
  final ScenarioModel scenario;

  const _DramaticChoiceHeader({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.64),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scenario.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Difficulty: ${scenario.difficulty}')),
                Chip(label: Text(scenario.theme)),
                if (scenario.roleMechanicType != null)
                  Chip(label: Text(scenario.roleMechanicType!)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              scenario.task,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinematicFallbackScenario extends StatelessWidget {
  final RoleScenarioModel roleScenario;
  final ScenarioModel scenario;
  final int chapterIndex;

  const _CinematicFallbackScenario({
    required this.roleScenario,
    required this.scenario,
    required this.chapterIndex,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Cinematic scene data is unavailable.')),
    );
  }
}


Widget _sceneTransition({
  required Widget child,
  required Animation<double> animation,
  required String transitionType,
}) {
  if (AnimationService.instance.isReducedMotion) {
    return child;
  }

  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  switch (transitionType.toLowerCase()) {
    case 'slide':
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    case 'zoom':
      return ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    case 'cut':
      return child;
    case 'fade':
    default:
      return FadeTransition(opacity: curved, child: child);
  }
}

Color _emotionColor(BuildContext context, String emotion) {
  switch (emotion.toLowerCase()) {
    case 'angry':
    case 'panic':
    case 'tense':
      return Colors.orangeAccent;
    case 'worried':
    case 'concerned':
      return Colors.amberAccent;
    case 'confident':
    case 'calm':
      return Colors.lightGreenAccent;
    case 'serious':
    case 'focused':
      return Colors.lightBlueAccent;
    case 'happy':
    case 'relieved':
      return Colors.pinkAccent.shade100;
    default:
      return Theme.of(context).colorScheme.tertiary;
  }
}

IconData _emotionIcon(String emotion) {
  switch (emotion.toLowerCase()) {
    case 'angry':
    case 'panic':
    case 'tense':
      return Icons.warning_amber;
    case 'worried':
    case 'concerned':
      return Icons.help_outline;
    case 'confident':
    case 'calm':
      return Icons.verified;
    case 'serious':
    case 'focused':
      return Icons.psychology;
    case 'happy':
    case 'relieved':
      return Icons.sentiment_satisfied_alt;
    default:
      return Icons.chat_bubble_outline;
  }
}

IconData _transitionIcon(String transitionType) {
  switch (transitionType.toLowerCase()) {
    case 'cut':
      return Icons.content_cut;
    case 'slide':
      return Icons.swipe;
    case 'zoom':
      return Icons.zoom_in;
    default:
      return Icons.auto_awesome;
  }
}

Duration _transitionDuration(String transitionType) {
  switch (transitionType.toLowerCase()) {
    case 'cut':
      return const Duration(milliseconds: 80);
    case 'slide':
      return const Duration(milliseconds: 420);
    case 'zoom':
      return const Duration(milliseconds: 520);
    default:
      return const Duration(milliseconds: 320);
  }
}
