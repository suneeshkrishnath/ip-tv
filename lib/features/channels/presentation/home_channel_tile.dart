import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ip_tv/core/cache/logo_cache_manager.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';

class HomeChannelTile extends StatelessWidget {
  const HomeChannelTile({
    required this.channel,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.compact = false,
    super.key,
  });

  final Channel channel;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: compact ? 124 : 96,
      height: compact ? 96 : 122,
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, compact ? 8 : 14, 8, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 58,
                        height: compact ? 38 : 50,
                        child: _ChannelLogo(channel: channel),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (!compact && channel.category.isNotEmpty)
                        Text(
                          channel.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: isFavorite ? colors.primary : colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelLogo extends StatelessWidget {
  const _ChannelLogo({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final logoUrl = channel.logoUrl;
    if (logoUrl == null || logoUrl.isEmpty) {
      return const Icon(Icons.live_tv, size: 34);
    }
    return CachedNetworkImage(
      imageUrl: logoUrl,
      cacheManager: logoCacheManager,
      fit: BoxFit.contain,
      errorWidget: (_, _, _) => const Icon(Icons.live_tv, size: 34),
    );
  }
}
