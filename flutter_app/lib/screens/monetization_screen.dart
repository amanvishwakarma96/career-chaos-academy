import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../models/product_model.dart';
import '../services/monetization_service.dart';
import '../widgets/empty_state.dart';

class MonetizationScreen extends StatefulWidget {
  const MonetizationScreen({super.key});

  @override
  State<MonetizationScreen> createState() => _MonetizationScreenState();
}

class _MonetizationScreenState extends State<MonetizationScreen> {
  late Future<ProductCatalogModel> _catalogFuture;
  String _status = 'Purchase system is in placeholder mode for development.';

  @override
  void initState() {
    super.initState();
    _catalogFuture = MonetizationService.instance.loadCatalog();
  }

  void _reload() {
    setState(() {
      _catalogFuture = MonetizationService.instance.loadCatalog();
    });
  }

  Future<void> _preview(ProductModel product) async {
    final preview = await MonetizationService.instance.loadPremiumPreview(product.id);
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final body = preview['preview'];
        final previewMap = body is Map ? Map<String, dynamic>.from(body) : product.preview;
        final items = previewMap['includedItems'] is List ? previewMap['includedItems'] as List : const <Object>[];
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  previewMap['title']?.toString() ?? product.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(previewMap['description']?.toString() ?? product.description),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(product.productType)),
                    Chip(label: Text(product.priceType)),
                    Chip(label: Text(product.displayPrice)),
                    Chip(label: Text((preview['locked'] == true) ? 'Locked' : 'Accessible')),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Included preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                for (final item in items)
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(item.toString()),
                  ),
                const SizedBox(height: 12),
                Text(
                  previewMap['lockedMessage']?.toString() ?? 'This is a preview. Premium gameplay unlocks only after entitlement check passes.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _runPlaceholder(ProductModel product) async {
    PurchasePlaceholderResultModel result;
    if (product.isSubscription) {
      result = await MonetizationService.instance.subscriptionPlaceholder(product.id);
    } else if (product.isCertificatePayment) {
      result = await MonetizationService.instance.certificatePaymentPlaceholder(product.id);
    } else if (product.isCorporateLicense) {
      result = await MonetizationService.instance.corporateLicensePlaceholder(product.id);
    } else {
      result = await MonetizationService.instance.purchasePlaceholder(product.id);
    }
    if (!mounted) return;
    setState(() {
      _status = result.message.isNotEmpty ? result.message : 'Placeholder result: ${result.status}';
      _catalogFuture = MonetizationService.instance.loadCatalog(preferApi: false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.paymentRequired ? 'External payment integration required later.' : 'No payment required in development mode.')),
    );
  }

  Future<void> _restore() async {
    final restored = await MonetizationService.instance.restorePurchasesPlaceholder();
    if (!mounted) return;
    setState(() {
      _status = 'Restore placeholder found ${restored.length} active entitlement(s).';
    });
  }

  Widget _productCard(ProductModel product, bool monetizationEnabled, bool noPaymentRequired) {
    final locked = monetizationEnabled && product.isPremium;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(locked ? Icons.lock : Icons.lock_open),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(product.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(product.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(product.productType)),
                Chip(label: Text(product.priceType)),
                Chip(label: Text(product.displayPrice)),
                if (locked) const Chip(label: Text('Premium locked')),
                if (!monetizationEnabled) const Chip(label: Text('Monetization disabled')),
                if (noPaymentRequired) const Chip(label: Text('Dev: no payment')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => _preview(product),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Preview'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: product.isFree ? null : () => _runPlaceholder(product),
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(product.isSubscription ? 'Subscribe placeholder' : 'Purchase placeholder'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.isFree
                  ? 'Free content remains accessible.'
                  : 'Locked until entitlement check passes. Development mode grants a placeholder entitlement without payment.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monetization System'),
        actions: [
          IconButton(
            tooltip: 'Restore purchases placeholder',
            onPressed: _restore,
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      body: FutureBuilder<ProductCatalogModel>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.payments,
              title: 'Monetization catalog unavailable',
              message: 'Free individual game mode still works. Reload the product catalog when ready.',
              actionLabel: 'Reload',
              onActionPressed: _reload,
            );
          }
          final catalog = snapshot.data ?? const ProductCatalogModel();
          if (catalog.products.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2,
              title: 'No products configured',
              message: 'Add ProductModel entries to enable premium previews and placeholders.',
              actionLabel: 'Reload',
              onActionPressed: _reload,
            );
          }
          return ResponsiveContent(
            child: ListView(
              padding: ResponsiveLayout.pagePadding(context),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Purchase-ready architecture', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(_status),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(catalog.monetization.enabled ? 'Feature flag: enabled' : 'Feature flag: disabled')),
                            Chip(label: Text(catalog.monetization.noPaymentRequiredInDevelopment ? 'Development: no payment required' : 'Payment required outside dev')),
                            Chip(label: Text('${catalog.products.length} products')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final product in catalog.products) ...[
                  _productCard(product, catalog.monetization.enabled, catalog.monetization.noPaymentRequiredInDevelopment),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
