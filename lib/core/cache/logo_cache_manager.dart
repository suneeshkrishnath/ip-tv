import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Keeps channel logos on disk for a month so they show offline.
final logoCacheManager = CacheManager(
  Config(
    'channelLogos',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 1000,
  ),
);
