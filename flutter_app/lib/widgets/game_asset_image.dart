import 'package:flutter/material.dart';

import '../core/asset_registry.dart';
import 'missing_asset_placeholder.dart';

class GameAssetImage extends StatelessWidget {
  final String? reference;
  final GameAssetType type;
  final BoxFit fit;
  final Alignment alignment;
  final Widget Function(BuildContext context, String? reference)? fallbackBuilder;
  final String? semanticLabel;

  const GameAssetImage({
    super.key,
    required this.reference,
    required this.type,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fallbackBuilder,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = AssetRegistry.resolve(reference, type: type);
    if (resolved == null) {
      return _fallback(context);
    }

    if (AssetRegistry.isRemoteUrl(resolved)) {
      return Image.network(
        resolved,
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return _LoadingAsset(reference: reference);
        },
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    return Image.asset(
      resolved,
      fit: fit,
      alignment: alignment,
      semanticLabel: semanticLabel,
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final builder = fallbackBuilder;
    if (builder != null) {
      return builder(context, reference);
    }
    return MissingAssetPlaceholder(reference: reference);
  }
}

class _LoadingAsset extends StatelessWidget {
  final String? reference;

  const _LoadingAsset({required this.reference});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MissingAssetPlaceholder(
          reference: reference,
          icon: Icons.downloading_outlined,
        ),
        const Center(child: CircularProgressIndicator.adaptive()),
      ],
    );
  }
}
