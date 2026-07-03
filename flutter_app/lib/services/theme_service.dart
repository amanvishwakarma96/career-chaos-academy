import 'package:flutter/material.dart';

class ThemeService {
  ThemeService._();

  static final ThemeService instance = ThemeService._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  void toggleLightDark() {
    final currentMode = themeMode.value;
    themeMode.value = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void useSystemMode() {
    themeMode.value = ThemeMode.system;
  }
}
