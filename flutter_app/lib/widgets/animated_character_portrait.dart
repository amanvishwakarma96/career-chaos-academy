import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/asset_registry.dart';
import '../services/animation_service.dart';
import 'game_asset_image.dart';

class AnimatedCharacterPortrait extends StatefulWidget {
  final String? imageReference;
  final String speaker;
  final String emotion;
  final String archetype;
  final Color color;

  const AnimatedCharacterPortrait({
    super.key,
    required this.imageReference,
    required this.speaker,
    required this.emotion,
    required this.archetype,
    required this.color,
  });

  @override
  State<AnimatedCharacterPortrait> createState() =>
      _AnimatedCharacterPortraitState();
}

class _AnimatedCharacterPortraitState extends State<AnimatedCharacterPortrait>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _idleController;

  bool get _shouldShake {
    final value = widget.emotion.toLowerCase();
    return value == 'angry' ||
        value == 'panic' ||
        value == 'comedy' ||
        value == 'tense';
  }

  bool get _shouldZoom {
    final value = widget.emotion.toLowerCase();
    return value == 'dramatic' ||
        value == 'focused' ||
        value == 'serious' ||
        value == 'confident';
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AnimationService.instance.isReducedMotion
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 520),
    )..forward();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _syncIdleAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedCharacterPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageReference != widget.imageReference ||
        oldWidget.emotion != widget.emotion ||
        oldWidget.speaker != widget.speaker) {
      _entranceController
        ..reset()
        ..forward();
    }
    _syncIdleAnimation();
  }

  void _syncIdleAnimation() {
    if (AnimationService.instance.isReducedMotion) {
      _idleController
        ..stop()
        ..value = 0;
      return;
    }
    if (!_idleController.isAnimating) {
      _idleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AnimationService.instance.isReducedMotion;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final portraitWidth = screenWidth < 390 ? 104.0 : 124.0;
    final portraitHeight = screenWidth < 390 ? 148.0 : 174.0;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _entranceController,
        _idleController,
      ]),
      builder: (context, child) {
        final entrance = Curves.easeOutBack.transform(
          _entranceController.value.clamp(0.0, 1.0).toDouble(),
        );
        final idle = reducedMotion ? 0.0 : _idleController.value;
        final shake = !reducedMotion && _shouldShake
            ? math.sin(_entranceController.value * math.pi * 8) *
                (1 - _entranceController.value) *
                8
            : 0.0;
        final dramaticScale = _shouldZoom ? 0.94 + entrance * 0.06 : 1.0;
        final idleScale = 1 + idle * 0.012;
        final idleOffset = reducedMotion ? 0.0 : -idle * 2.5;

        return Opacity(
          opacity: entrance.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(
            offset: Offset(-22 * (1 - entrance) + shake, idleOffset),
            child: Transform.scale(
              scale: dramaticScale * idleScale,
              alignment: Alignment.bottomCenter,
              child: _PortraitFrame(
                imageReference: widget.imageReference,
                speaker: widget.speaker,
                emotion: widget.emotion,
                archetype: widget.archetype,
                color: widget.color,
                width: portraitWidth,
                height: portraitHeight,
                glowStrength: 0.35 + idle * 0.18,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PortraitFrame extends StatelessWidget {
  final String? imageReference;
  final String speaker;
  final String emotion;
  final String archetype;
  final Color color;
  final double width;
  final double height;
  final double glowStrength;

  const _PortraitFrame({
    required this.imageReference,
    required this.speaker,
    required this.emotion,
    required this.archetype,
    required this.color,
    required this.width,
    required this.height,
    required this.glowStrength,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AnimationService.instance.duration(
        const Duration(milliseconds: 260),
      ),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.92), width: 2.5),
        color: Colors.black.withOpacity(0.38),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(glowStrength),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.42),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameAssetImage(
            reference: imageReference,
            type: GameAssetType.character,
            fit: BoxFit.cover,
            semanticLabel: '$speaker $emotion portrait',
            fallbackBuilder: (_, __) => _PortraitFallback(
              speaker: speaker,
              emotion: emotion,
              color: color,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.78),
                ],
                stops: const <double>[0, 0.58, 1],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  speaker,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: const <Shadow>[
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  archetype.isEmpty ? emotion : archetype,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitFallback extends StatelessWidget {
  final String speaker;
  final String emotion;
  final Color color;

  const _PortraitFallback({
    required this.speaker,
    required this.emotion,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initial = speaker.trim().isEmpty ? '?' : speaker.trim()[0];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: <Color>[color, Colors.black87]),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            initial.toUpperCase(),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            emotion,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
