import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/responsive_layout.dart';
import '../models/mini_game_progress_model.dart';
import '../models/mini_game_result_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../services/progress_service.dart';
import '../services/learning_analytics_service.dart';
import '../services/audio_service.dart';
import '../services/animation_service.dart';
import '../widgets/choice_button.dart';
import '../widgets/dialogue_panel.dart';
import '../widgets/info_panel.dart';
import '../widgets/mini_game_status_card.dart';
import 'dialogue_scene_screen.dart';
import 'mini_game_screen.dart';
import 'result_screen.dart';

class ScenarioScreen extends StatefulWidget {
  final RoleScenarioModel roleScenario;
  final ScenarioModel scenario;
  final int chapterIndex;

  const ScenarioScreen({
    super.key,
    required this.roleScenario,
    required this.scenario,
    required this.chapterIndex,
  });

  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  MiniGameResultModel? _currentMiniGameResult;
  late final DateTime _chapterOpenedAt;

  @override
  void initState() {
    super.initState();
    _chapterOpenedAt = DateTime.now();
    unawaited(LearningAnalyticsService.instance.trackChapterStarted(
      roleId: roleScenario.role.id,
      chapterId: scenario.id,
    ));
  }

  @override
  void dispose() {
    final elapsed = DateTime.now().difference(_chapterOpenedAt).inSeconds;
    unawaited(LearningAnalyticsService.instance.trackTimeSpent(
      roleId: roleScenario.role.id,
      chapterId: scenario.id,
      seconds: elapsed,
    ));
    super.dispose();
  }

  ScenarioModel get scenario => widget.scenario;
  RoleScenarioModel get roleScenario => widget.roleScenario;
  int get chapterIndex => widget.chapterIndex;

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
    if (scenario.miniGame == null) {
      return true;
    }
    return _currentMiniGameResult != null || _savedMiniGameProgress != null;
  }

  Future<void> _openMiniGame() async {
    final miniGame = scenario.miniGame;
    if (miniGame == null) {
      return;
    }

    await AudioService.instance.stopSceneAudio();
    final miniGameStartedAt = DateTime.now();

    final result = await Navigator.of(context).push<MiniGameResultModel>(
      AnimationService.instance.motionRoute<MiniGameResultModel>(
        settings: const RouteSettings(name: AppRoutes.miniGame),
        transition: MotionRouteTransition.slideUp,
        builder: (_) => MiniGameScreen(miniGame: miniGame),
      ),
    );

    if (result == null) {
      return;
    }

    await ProgressService.instance.recordMiniGameResult(
      roleScenario: roleScenario,
      chapter: scenario,
      result: result,
    );
    unawaited(LearningAnalyticsService.instance.trackMiniGameAttempt(
      roleId: roleScenario.role.id,
      chapterId: scenario.id,
      miniGameId: result.miniGameId,
      passed: result.isSuccess,
      timeSpentSeconds: DateTime.now().difference(miniGameStartedAt).inSeconds,
      scoreDelta: result.scoreImpact.toJson(),
    ));

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
              ? 'Mini-game score saved. Story choices unlocked!'
              : 'Funny failure saved. Story choices unlocked anyway!',
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
    unawaited(LearningAnalyticsService.instance.trackChoiceSelected(
      roleId: roleScenario.role.id,
      chapterId: scenario.id,
      choiceId: 'choice_$choiceIndex',
      scoreDelta: choice.scoreImpact.toJson(),
    ));

    final progressUpdate = await ProgressService.instance.completeChapter(
      roleScenario: roleScenario,
      chapter: scenario,
      scoreImpact: choice.scoreImpact,
      outcome: choice.outcome,
    );

    unawaited(LearningAnalyticsService.instance.trackChapterCompleted(
      roleId: roleScenario.role.id,
      chapterId: scenario.id,
      timeSpentSeconds: DateTime.now().difference(_chapterOpenedAt).inSeconds,
      scoreDelta: choice.scoreImpact.toJson(),
    ));

    if (!context.mounted) {
      return;
    }

    await AudioService.instance.playResultSfx(
      isSuccess: choice.scoreImpact.chaos <= 0,
    );
    if (progressUpdate.hasNewBadges || progressUpdate.didRankUp) {
      unawaited(AudioService.instance.playBadgeUnlock());
    }

    Navigator.of(context).push(
      AnimationService.instance.motionRoute<void>(
        transition: MotionRouteTransition.fadeScale,
        builder: (_) => ResultScreen(
          scenario: scenario,
          choice: choice,
          isLastChapter: scenario.isFinale || chapterIndex >= roleScenario.totalChapters - 1,
          progressUpdate: progressUpdate,
          roleScenario: roleScenario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (scenario.hasCinematicScenes) {
      return DialogueSceneScreen(
        roleScenario: roleScenario,
        scenario: scenario,
        chapterIndex: chapterIndex,
      );
    }

    final miniGame = scenario.miniGame;

    return Scaffold(
      appBar: AppBar(
        title: Text('${scenario.role.name} • Chapter ${chapterIndex + 1}'),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          child: ListView(
            padding: ResponsiveLayout.pagePadding(context),
            children: [
              Text(
                scenario.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.menu_book, size: 16),
                    label: Text(
                      'Chapter ${chapterIndex + 1}/${roleScenario.totalChapters}',
                    ),
                  ),
                  Chip(label: Text('Difficulty: ${scenario.difficulty}')),
                  Chip(label: Text(scenario.theme)),
                  if (miniGame != null) Chip(label: Text(miniGame.type.label)),
                ],
              ),
              const SizedBox(height: 20),
              DialoguePanel(
                speaker: '${scenario.role.name} narrator',
                body: scenario.story,
                useTypingEffect: true,
              ),
              const SizedBox(height: 12),
              DialoguePanel(
                speaker: 'Mission Brief',
                body: scenario.task,
                icon: Icons.assignment,
              ),
              if (scenario.professionalLearningPoint.isNotEmpty) ...[
                const SizedBox(height: 12),
                InfoPanel(
                  title: 'Professional Learning Point',
                  body: scenario.professionalLearningPoint,
                ),
              ],
              if (scenario.safetyDisclaimer != null) ...[
                const SizedBox(height: 12),
                InfoPanel(
                  title: 'Safety Note',
                  body: scenario.safetyDisclaimer!,
                ),
              ],
              if (miniGame != null) ...[
                const SizedBox(height: 12),
                MiniGameStatusCard(
                  savedProgress: _savedMiniGameProgress,
                  currentResult: _currentMiniGameResult,
                  onStartPressed: _openMiniGame,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                _canShowChoices
                    ? 'What will you do?'
                    : 'Complete the mini-game to continue the story.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                          onPressed: () => _completeChapterAndShowOutcome(
                            context: context,
                            choiceIndex: entry.key,
                          ),
                        ),
                      ),
                    )
              else
                const InfoPanel(
                  title: 'Story paused',
                  body:
                      'Your manager is staring dramatically. Finish the mini-game first, then the choice buttons will appear.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
