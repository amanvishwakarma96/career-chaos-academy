import 'package:flutter/material.dart';

import '../services/animation_service.dart';
import 'game_asset_image.dart';

class ParallaxSceneBackground extends StatelessWidget {
  final String? reference;
  final GameAssetType type;
  final Widget Function(BuildContext context, Object? error)? fallbackBuilder;

  const ParallaxSceneBackground({
    super.key,
    required this.reference,
    required this.type,
    this.fallbackBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AnimationService.instance.reducedMotion,
      builder: (context, reducedMotion, _) {
        final image = reference == null
            ? fallbackBuilder?.call(context, null) ?? const SizedBox.expand()
            : GameAssetImage(
                reference: reference,
                type: type,
                fit: BoxFit.cover,
                fallbackBuilder: fallbackBuilder,
              );

        if (reducedMotion) {
          return image;
        }

        return TweenAnimationBuilder<double>(
          key: ValueKey<String>('parallax-${reference ?? 'fallback'}'),
          tween: Tween<double>(begin: -1, end: 1),
          duration: const Duration(seconds: 12),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(value * 10, 0),
              child: Transform.scale(scale: 1.04, child: child),
            );
          },
          child: image,
        );
      },
    );
  }
}
