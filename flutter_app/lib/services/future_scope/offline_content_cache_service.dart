class OfflineContentCacheStrategy {
  final String contentPackId;
  final String version;
  final Duration staleAfter;
  final bool allowBundledFallback;
  final bool allowRemoteRefresh;

  const OfflineContentCacheStrategy({
    this.contentPackId = 'core_roles',
    this.version = '1.0.0',
    this.staleAfter = const Duration(days: 30),
    this.allowBundledFallback = true,
    this.allowRemoteRefresh = false,
  });
}

class OfflineContentCacheService {
  OfflineContentCacheService._();

  static final OfflineContentCacheService instance = OfflineContentCacheService._();

  OfflineContentCacheStrategy strategy = const OfflineContentCacheStrategy();

  bool shouldUseBundledFallback({DateTime? lastUpdated, DateTime? now}) {
    if (lastUpdated == null) return true;
    final current = now ?? DateTime.now();
    return current.difference(lastUpdated) > strategy.staleAfter;
  }

  Future<void> prepareForFutureRemotePacks() async {
    // Placeholder: in a future phase, this can hydrate signed content packs
    // into app storage and verify manifest checksums before activation.
  }
}
