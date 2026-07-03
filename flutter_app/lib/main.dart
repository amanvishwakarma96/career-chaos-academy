import 'package:flutter/material.dart';

import 'app/career_chaos_app.dart';
import 'services/progress_service.dart';
import 'services/release_monitoring_service.dart';
import 'services/animation_service.dart';
import 'services/audio_service.dart';
import 'services/future_scope/content_version_service.dart';
import 'services/future_scope/feature_flag_service.dart';
import 'services/future_scope/localization_service.dart';
import 'services/future_scope/remote_config_service.dart';
import 'services/future_scope/role_plugin_registry.dart';
import 'services/game_visual_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReleaseMonitoringService.instance.initialize();
  await ReleaseMonitoringService.instance.logAppStart();
  await AnimationService.instance.load();
  await GameVisualSettingsService.instance.load();
  await AudioService.instance.load();
  await FeatureFlagService.instance.load();
  await RemoteConfigService.instance.loadDefaults();
  await ContentVersionService.instance.load();
  await LocalizationTextService.instance.load();
  await RolePluginRegistry.instance.load();
  await ProgressService.instance.load();
  runApp(const CareerChaosApp());
}
