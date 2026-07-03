import 'package:flutter/material.dart';

import '../services/future_scope/content_version_service.dart';
import '../services/future_scope/feature_flag_service.dart';
import '../services/future_scope/multiplayer_service.dart';
import '../services/future_scope/offline_content_cache_service.dart';
import '../services/future_scope/role_plugin_registry.dart';

class FutureArchitectureScreen extends StatelessWidget {
  const FutureArchitectureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = ContentVersionService.instance.contentVersion;
    final assets = ContentVersionService.instance.assetVersion;
    final cache = OfflineContentCacheService.instance.strategy;
    final plugins = RolePluginRegistry.instance.plugins;

    return Scaffold(
      appBar: AppBar(title: const Text('Future Architecture')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Feature Flags'),
              subtitle: Text(
                FeatureFlagService.instance.snapshot().entries
                    .map((entry) => '${entry.key}: ${entry.value ? 'on' : 'off'}')
                    .join('\n'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Content Version'),
              subtitle: Text('${content?.contentPackId ?? 'core_roles'} @ ${content?.version ?? 'unknown'}'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Asset Version'),
              subtitle: Text('${assets?.assetPackId ?? 'base_visuals'} @ ${assets?.version ?? 'unknown'}'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.offline_pin),
              title: const Text('Offline Cache Strategy'),
              subtitle: Text(
                'Pack: ${cache.contentPackId}\nStale after: ${cache.staleAfter.inDays} days\nBundled fallback: ${cache.allowBundledFallback}',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.extension),
              title: const Text('Role Plugins'),
              subtitle: Text(plugins.map((plugin) => '${plugin.roleId} → ${plugin.pluginId}').join('\n')),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Multiplayer Placeholder'),
              subtitle: Text(MultiplayerService.instance.isAvailable
                  ? 'Future multiplayer flag is enabled.'
                  : 'Multiplayer architecture is present but disabled.'),
            ),
          ),
        ],
      ),
    );
  }
}
