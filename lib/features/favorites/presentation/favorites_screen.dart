import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ip_tv/features/channels/presentation/channel_card.dart';
import 'package:ip_tv/features/favorites/application/favorite_providers.dart';
import 'package:ip_tv/shared/widgets/empty_state_view.dart';
import 'package:ip_tv/shared/widgets/error_view.dart';
import 'package:ip_tv/shared/widgets/loading_widget.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteChannelsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.when(
        loading: () => const LoadingWidget(label: 'Loading favorites'),
        error: (error, _) => ErrorView(error: error),
        data: (channels) => channels.isEmpty
            ? const EmptyStateView(
                icon: Icons.favorite_border,
                title: 'No favorites yet',
                message: 'Favorite a channel to keep it close at hand.',
              )
            : ListView.builder(
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  return ChannelCard(
                    channel: channel,
                    isFavorite: true,
                    onTap: () => context.pushNamed('player', extra: channel),
                    onFavoritePressed: () => ref
                        .read(favoriteChannelsProvider.notifier)
                        .remove(channel),
                  );
                },
              ),
      ),
    );
  }
}