import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimationService {
  AnimationService._();

  static final AnimationService instance = AnimationService._();

  static const String _reducedMotionKey = 'career_chaos_reduced_motion';

  final ValueNotifier<bool> reducedMotion = ValueNotifier<bool>(false);

  bool get isReducedMotion => reducedMotion.value;
  bool get shouldAnimate => !isReducedMotion;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    reducedMotion.value = preferences.getBool(_reducedMotionKey) ?? false;
  }

  Future<void> setReducedMotion(bool value) async {
    if (reducedMotion.value == value) {
      return;
    }
    reducedMotion.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_reducedMotionKey, value);
  }

  Future<void> toggleReducedMotion() async {
    await setReducedMotion(!reducedMotion.value);
  }

  Duration duration(Duration normal, {Duration reduced = Duration.zero}) {
    return isReducedMotion ? reduced : normal;
  }

  Curve curve(Curve normal) {
    return isReducedMotion ? Curves.linear : normal;
  }

  bool shouldUseHeavyAnimation() {
    return !isReducedMotion;
  }

  PageRouteBuilder<T> motionRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    MotionRouteTransition transition = MotionRouteTransition.fadeScale,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration(const Duration(milliseconds: 320)),
      reverseTransitionDuration: duration(const Duration(milliseconds: 220)),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (isReducedMotion) {
          return child;
        }

        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        switch (transition) {
          case MotionRouteTransition.slideUp:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          case MotionRouteTransition.slideLeft:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          case MotionRouteTransition.fade:
            return FadeTransition(opacity: curved, child: child);
          case MotionRouteTransition.fadeScale:
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
                child: child,
              ),
            );
        }
      },
    );
  }
}

enum MotionRouteTransition {
  fade,
  fadeScale,
  slideUp,
  slideLeft,
}
