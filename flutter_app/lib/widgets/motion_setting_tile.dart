import 'package:flutter/material.dart';

import '../services/animation_service.dart';

class MotionSettingTile extends StatelessWidget {
  const MotionSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AnimationService.instance.reducedMotion,
      builder: (context, reducedMotion, _) {
        return SwitchListTile.adaptive(
          value: reducedMotion,
          onChanged: (value) => AnimationService.instance.setReducedMotion(value),
          secondary: const Icon(Icons.motion_photos_off),
          title: const Text('Reduced Motion'),
          subtitle: const Text(
            'Disables heavy cinematic motion, parallax, shake, zoom, and Lottie playback for accessibility and low-end devices.',
          ),
        );
      },
    );
  }
}
