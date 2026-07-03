import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/scenario_pack_model.dart';
import '../services/scenario_pack_service.dart';
import '../widgets/empty_state.dart';

class ScenarioPackMarketplaceScreen extends StatefulWidget {
  const ScenarioPackMarketplaceScreen({super.key});

  @override
  State<ScenarioPackMarketplaceScreen> createState() => _ScenarioPackMarketplaceScreenState();
}

class _ScenarioPackMarketplaceScreenState extends State<ScenarioPackMarketplaceScreen> {
  late Future<List<ScenarioPackModel>> _packsFuture;

  @override
  void initState() {
    super.initState();
    _packsFuture = ScenarioPackService.instance.loadPublishedPacks();
  }

  void _reload() {
    setState(() {
      _packsFuture = ScenarioPackService.instance.loadPublishedPacks();
    });
  }

  Future<void> _cachePack(ScenarioPackModel pack) async {
    await ScenarioPackService.instance.cachePackForOffline(pack);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${pack.title} is ready for offline play.')),
    );
  }

  void _previewPack(ScenarioPackModel pack) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(18),
              children: [
                Text(pack.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(pack.description),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(pack.roleName)),
                    Chip(label: Text(pack.difficulty)),
                    Chip(label: Text(pack.priceType.toUpperCase())),
                    Chip(label: Text('Safety: ${pack.safetyStatus}')),
                    Chip(label: Text('${pack.chapterCount} chapters')),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Chapters', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final chapter in pack.chapterJson)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text('${chapter['title'] ?? 'Untitled Chapter'}'),
                      subtitle: Text('${chapter['learningObjective'] ?? chapter['theme'] ?? 'Creator chapter'}'),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Compatibility', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text('Requires app ${pack.compatibility.minAppVersion}+ • Schema ${pack.compatibility.schemaVersion}'),
                const SizedBox(height: 12),
                Text('Safety review: ${pack.safetyReview.status}. Invalid or unreviewed professional content cannot be published.'),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scenario Marketplace')),
      body: FutureBuilder<List<ScenarioPackModel>>(
        future: _packsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.storefront,
              title: 'Marketplace unavailable',
              message: 'Scenario packs could not be loaded. Bundled story mode still works.',
              actionLabel: 'Retry',
              onActionPressed: _reload,
            );
          }
          final packs = snapshot.data ?? const <ScenarioPackModel>[];
          if (packs.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No published packs yet',
              message: 'Creator Studio packs appear here after safety review and publishing.',
              actionLabel: 'Reload',
              onActionPressed: _reload,
            );
          }
          return ResponsiveContent(
            child: ListView.separated(
              padding: ResponsiveLayout.pagePadding(context),
              itemCount: packs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pack = packs[index];
                return Card(
                  elevation: pack.isFeatured ? 3 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(pack.isFeatured ? Icons.workspace_premium : Icons.extension),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(pack.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(pack.description),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(pack.roleName)),
                            Chip(label: Text(pack.difficulty)),
                            Chip(label: Text(pack.priceType)),
                            Chip(label: Text('v${pack.version}')),
                            Chip(label: Text('★ ${pack.rating.average.toStringAsFixed(1)} (${pack.rating.count})')),
                            if (pack.isFeatured) const Chip(label: Text('Featured')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: () => _previewPack(pack),
                              icon: const Icon(Icons.visibility),
                              label: const Text('Preview'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: pack.supportsOfflineCache ? () => _cachePack(pack) : null,
                              icon: const Icon(Icons.download_for_offline),
                              label: const Text('Cache offline'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Published creator packs are automatically included in the role chapter list when compatible.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
