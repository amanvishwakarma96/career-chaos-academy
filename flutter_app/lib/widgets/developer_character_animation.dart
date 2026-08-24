import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/asset_registry.dart';
import '../services/animation_service.dart';

enum DeveloperCharacterMode {
  idle,
  walk,
  worried,
}

class DeveloperCharacterAnimation extends StatelessWidget {
  const DeveloperCharacterAnimation({
    super.key,
    this.mode = DeveloperCharacterMode.idle,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel = 'Developer character',
  });

  final DeveloperCharacterMode mode;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String semanticLabel;

  static const Map<DeveloperCharacterMode, String> assetKeys =
      <DeveloperCharacterMode, String>{
    DeveloperCharacterMode.idle: 'anim_developer_idle',
    DeveloperCharacterMode.walk: 'anim_developer_walk',
    DeveloperCharacterMode.worried: 'anim_developer_worried',
  };

  static bool isDeveloperReference(String? reference) {
    final value = reference?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return false;
    }
    return value.startsWith('char_developer_') ||
        value.contains('/developer_neutral.png') ||
        value.contains('/developer_focused.png') ||
        value.contains('/developer_worried.png');
  }

  static DeveloperCharacterMode modeForEmotion(String emotion) {
    final value = emotion.trim().toLowerCase();
    if (value == 'worried' ||
        value == 'panic' ||
        value == 'tense' ||
        value == 'comedy') {
      return DeveloperCharacterMode.worried;
    }
    return DeveloperCharacterMode.idle;
  }

  static String assetPathFor(DeveloperCharacterMode mode) {
    final key = assetKeys[mode]!;
    return AssetRegistry.resolve(
          key,
          type: GameAssetType.lottie,
          allowUnknownAssetPath: false,
        ) ??
        'assets/game/lottie/developer_idle.json';
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AnimationService.instance.isReducedMotion;
    final path = assetPathFor(mode);

    return Semantics(
      image: true,
      label: semanticLabel,
      child: Lottie.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        repeat: !reducedMotion,
        animate: !reducedMotion,
        frameRate: FrameRate.max,
      ),
    );
  }
}
