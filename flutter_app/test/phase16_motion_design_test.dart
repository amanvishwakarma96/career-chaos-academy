import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:career_chaos_academy/services/animation_service.dart';
import 'package:career_chaos_academy/widgets/motion_feedback_animation.dart';

void main() {
  group('Phase 16 motion design system', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });
    test('AnimationService toggles reduced motion safely', () async {
      await AnimationService.instance.setReducedMotion(false);
      expect(AnimationService.instance.isReducedMotion, isFalse);
      expect(AnimationService.instance.shouldAnimate, isTrue);
      expect(
        AnimationService.instance.duration(const Duration(milliseconds: 300)),
        const Duration(milliseconds: 300),
      );

      await AnimationService.instance.setReducedMotion(true);
      expect(AnimationService.instance.isReducedMotion, isTrue);
      expect(AnimationService.instance.shouldAnimate, isFalse);
      expect(
        AnimationService.instance.duration(const Duration(milliseconds: 300)),
        Duration.zero,
      );
    });

    test('motion route falls back to non-blocking route in reduced motion', () async {
      await AnimationService.instance.setReducedMotion(true);
      final route = AnimationService.instance.motionRoute<void>(
        settings: const RouteSettings(name: '/test-motion'),
        builder: (_) => const SizedBox.shrink(),
      );
      expect(route.settings.name, '/test-motion');
      expect(route.transitionDuration, Duration.zero);
    });

    test('Lottie feedback assets are valid JSON placeholders', () {
      final files = <String>[
        'assets/game/lottie/success.json',
        'assets/game/lottie/failure.json',
        'assets/game/lottie/badge_unlock.json',
      ];

      for (final path in files) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path should exist');
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(json['v'], isNotNull);
        expect(json['layers'], isA<List<dynamic>>());
      }
    });

    testWidgets('MotionFeedbackAnimation uses static icon when reduced motion is on',
        (tester) async {
      await AnimationService.instance.setReducedMotion(true);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MotionFeedbackAnimation(type: MotionFeedbackType.success),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
