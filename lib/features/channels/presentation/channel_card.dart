import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/presentation/favorite_button.dart';

class ChannelCard extends StatelessWidget {
  const ChannelCard({
    required this.channel,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoritePressed,
    super.key,
  });

  final Channel channel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              FavoriteButton(
                isFavorite: isFavorite,
                onPressed: onFavoritePressed,
              ),
              IconButton(
                tooltip: 'Play ${channel.name}',
                onPressed: onTap,
                icon: const Icon(Icons.play_arrow),
              ),
            ],
          ),
      ),
    );
  }
}