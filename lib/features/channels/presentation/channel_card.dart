import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';

class ChannelCard extends StatelessWidget {
  const ChannelCard({
    required this.channel,
    required this.onTap,
    super.key,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Channel channel;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 56,
                child: channel.logoUrl == null
                    ? Icon(Icons.live_tv, color: colors.onSurfaceVariant)
                    : CachedNetworkImage(
                        imageUrl: channel.logoUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.live_tv,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (channel.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        channel.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onFavoriteToggle != null)
                IconButton(
                  tooltip:
                      isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? colors.primary : null,
                  ),
                ),
              const Icon(Icons.play_arrow),
            ],
          ),
        ),
      ),
    );
  }
}