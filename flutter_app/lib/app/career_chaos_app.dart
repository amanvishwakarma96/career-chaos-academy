import 'package:flutter/material.dart';

import '../core/app_metadata.dart';
import '../core/app_theme.dart';
import '../screens/role_selection_screen.dart';
import '../services/release_monitoring_service.dart';
import '../services/theme_service.dart';

class CareerChaosApp extends StatelessWidget {
  const CareerChaosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppMetadata.appName,
          theme: buildCareerChaosTheme(),
          darkTheme: buildCareerChaosDarkTheme(),
          themeMode: themeMode,
          navigatorObservers: ReleaseMonitoringService.instance.navigatorObservers,
          home: const RoleSelectionScreen(),
        );
      },
    );
  }
}
