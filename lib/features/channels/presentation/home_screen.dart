import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ip_tv/core/constants/initial_playlist_sources.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/channels/presentation/channel_card.dart';
import 'package:ip_tv/features/epg/application/epg_providers.dart';
import 'package:ip_tv/features/favorites/application/favorites_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/shared/widgets/app_search_bar.dart';
import 'package:ip_tv/shared/widgets/empty_state_view.dart';
import 'package:ip_tv/shared/widgets/error_view.dart';
import 'package:ip_tv/shared/widgets/loading_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSource = ref.watch(selectedPlaylistSourceProvider);
    final sources =
        ref.watch(playlistSourcesProvider).value ?? initialPlaylistSources;
    final playlistState = ref.watch(currentPlaylistProvider);
    final query = ref.watch(channelSearchQueryProvider);
    final selectedCategory = ref.watch(selectedChannelCategoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Channels'),
        actions: [
          IconButton(
            tooltip: 'Manage playlists',
            icon: const Icon(Icons.library_add),
            onPressed: () => context.pushNamed('playlists'),
          ),
          IconButton(
            tooltip: 'Recently watched',
            icon: const Icon(Icons.history),
            onPressed: () => context.pushNamed('recent'),
          ),
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.favorite),
            onPressed: () => context.pushNamed('favorites'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PlaylistSource>(
                      key: ValueKey('${selectedSource.id}-${sources.length}'),
                      initialValue: selectedSource,
                      decoration: const InputDecoration(
                        labelText: 'Playlist source',
                      ),
                      items: sources
                          .map(
                            (source) => DropdownMenuItem(
                              value: source,
                              child: Text(source.name),
                            ),
                          )
                          .toList(),
                      onChanged: (source) {
                        if (source != null) {
                          ref
                              .read(selectedPlaylistSourceProvider.notifier)
                              .select(source);
                          ref
                              .read(currentPlaylistProvider.notifier)
                              .showCached(source);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Load playlist',
                    onPressed: playlistState.isLoading
                        ? null
                        : () => ref
                            .read(currentPlaylistProvider.notifier)
                            .loadSource(selectedSource),
                    icon: const Icon(Icons.download),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: AppSearchBar(
                query: query,
                onChanged: ref
                    .read(channelSearchQueryProvider.notifier)
                    .update,
              ),
            ),
            Expanded(
              child: playlistState.when(
                loading: () => const LoadingWidget(label: 'Loading channels'),
                error: (error, _) => ErrorView(
                  error: error,
                  onRetry: () => ref
                      .read(currentPlaylistProvider.notifier)
                      .loadSource(selectedSource),
                ),
                data: (playlist) => _buildPlaylist(
                  context,
                  ref,
                  playlist,
                  query,
                  selectedCategory,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylist(
    BuildContext context,
    WidgetRef ref,
    Playlist? playlist,
    String query,
    String? selectedCategory,
  ) {
    if (playlist == null) {
      return EmptyStateView(
        icon: Icons.live_tv,
        title: 'No playlist loaded',
        message: 'Choose a source to browse its channels.',
        actionLabel: 'Load channels',
        onAction: () => ref
            .read(currentPlaylistProvider.notifier)
            .loadSource(ref.read(selectedPlaylistSourceProvider)),
      );
    }

    final guide = ref.watch(epgGuideProvider).value;
    final now = DateTime.now();
    final categories = playlist.channels
        .map((channel) => channel.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final channels = filterChannels(
      playlist.channels,
      query: query,
      category: selectedCategory,
    );

    return Column(
      children: [
        if (ref.watch(playlistOfflineProvider))
          MaterialBanner(
            leading: const Icon(Icons.cloud_off),
            content: const Text(
              'Could not refresh. Showing saved channels.',
            ),
            actions: [
              TextButton(
                onPressed: () => ref
                    .read(currentPlaylistProvider.notifier)
                    .loadSource(ref.read(selectedPlaylistSourceProvider)),
                child: const Text('Retry'),
              ),
            ],
          ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (_) => ref
                        .read(selectedChannelCategoryProvider.notifier)
                        .select(null),
                  ),
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) => ref
                          .read(selectedChannelCategoryProvider.notifier)
                          .select(category),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: channels.isEmpty
              ? const EmptyStateView(
                  icon: Icons.search_off,
                  title: 'No channels found',
                  message: 'Try another search or category.',
                )
              : ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return ChannelCard(
                      channel: channel,
                      nowPlaying: guide
                          ?.currentProgram(channel.epgId, now)
                          ?.title,
                      isFavorite: ref.watch(isFavoriteProvider(channel.id)),
                      onFavoriteToggle: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(channel),
                      onTap: () => _openPlayer(context, channel),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openPlayer(BuildContext context, Channel channel) {
    context.pushNamed('player', extra: channel);
  }
}
