import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ip_tv/core/constants/initial_playlist_sources.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/channels/presentation/home_channel_tile.dart';
import 'package:ip_tv/features/favorites/application/favorites_providers.dart';
import 'package:ip_tv/features/history/application/history_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSource = ref.watch(selectedPlaylistSourceProvider);
    final sources =
        ref.watch(playlistSourcesProvider).value ?? initialPlaylistSources;
    final playlistState = ref.watch(currentPlaylistProvider);
    final favorites = ref.watch(favoritesProvider).value ?? const [];
    final recent = ref.watch(recentlyWatchedProvider).value ?? const [];
    final channels = playlistState.value?.channels ?? const [];
    final categories =
        channels
            .map((channel) => channel.category)
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.live_tv, color: Color(0xFF20B7FF)),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nerampokku'),
                Text('Your world of entertainment'),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Browse channels',
            icon: const Icon(Icons.search),
            onPressed: () => _openChannels(context, 'all'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PlaylistSource>(
                        key: ValueKey('${selectedSource.id}-${sources.length}'),
                        initialValue: selectedSource,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.grid_view_rounded),
                          labelText: 'Browse channels',
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
                          if (source == null) return;
                          ref
                              .read(selectedPlaylistSourceProvider.notifier)
                              .select(source);
                          ref
                              .read(currentPlaylistProvider.notifier)
                              .showCached(source);
                          _openChannels(context, 'all');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Load selected playlist',
                      onPressed: playlistState.isLoading
                          ? null
                          : () => ref
                                .read(currentPlaylistProvider.notifier)
                                .loadSource(selectedSource),
                      icon: const Icon(Icons.download),
                    ),
                    IconButton(
                      tooltip: 'Manage playlists',
                      onPressed: () => context.pushNamed('playlists'),
                      icon: const Icon(Icons.playlist_add),
                    ),
                  ],
                ),
              ),
            ),
            if (ref.watch(playlistOfflineProvider))
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Offline mode: showing saved channels.'),
                ),
              ),
            _sectionHeader(
              context,
              title: 'Favorites',
              icon: Icons.favorite,
              action: favorites.isEmpty
                  ? null
                  : () => context.pushNamed('favorites'),
            ),
            if (favorites.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text('Your favorite channels will appear here.'),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 132,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: favorites.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final channel = favorites[index];
                      return HomeChannelTile(
                        channel: channel,
                        isFavorite: true,
                        onFavoriteToggle: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(channel),
                        onTap: () =>
                            context.pushNamed('player', extra: channel),
                      );
                    },
                  ),
                ),
              ),
            _sectionHeader(
              context,
              title: 'Browse by category',
              icon: Icons.grid_view_rounded,
              action: categories.isEmpty
                  ? null
                  : () => _openChannels(context, 'all'),
            ),
            if (categories.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: OutlinedButton.icon(
                    onPressed: playlistState.isLoading
                        ? null
                        : () => ref
                              .read(currentPlaylistProvider.notifier)
                              .loadSource(selectedSource),
                    icon: const Icon(Icons.download),
                    label: const Text('Load channels to browse categories'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.builder(
                  itemCount: categories.length.clamp(0, 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 54,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) => _CategoryTile(
                    title: categories[index],
                    color: _categoryColors[index % _categoryColors.length],
                    icon: _categoryIcon(categories[index]),
                    onTap: () => _openChannels(context, categories[index]),
                  ),
                ),
              ),
            _sectionHeader(
              context,
              title: 'Recently watched',
              icon: Icons.history,
              action: recent.isEmpty ? null : () => context.pushNamed('recent'),
            ),
            if (recent.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Text('Channels you play will appear here.'),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: recent.length.clamp(0, 10),
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final channel = recent[index];
                      return HomeChannelTile(
                        channel: channel,
                        compact: true,
                        isFavorite: ref.watch(isFavoriteProvider(channel.id)),
                        onFavoriteToggle: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(channel),
                        onTap: () =>
                            context.pushNamed('player', extra: channel),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            label: 'Channels',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              _openChannels(context, 'all');
            case 2:
              context.pushNamed('favorites');
            case 3:
              context.pushNamed('settings');
          }
        },
      ),
    );
  }

  void _openChannels(BuildContext context, String category) {
    context.pushNamed(
      'channels',
      pathParameters: {'category': Uri.encodeComponent(category)},
    );
  }
}

Widget _sectionHeader(
  BuildContext context, {
  required String title,
  required IconData icon,
  VoidCallback? action,
}) => SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (action != null)
          TextButton(onPressed: action, child: const Text('View all')),
      ],
    ),
  ),
);

const _categoryColors = [
  Color(0xFF5E2ACB),
  Color(0xFFC2185B),
  Color(0xFF078A56),
  Color(0xFF1749B6),
  Color(0xFFE26814),
  Color(0xFF008C95),
  Color(0xFF7728C8),
  Color(0xFFB78600),
];

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(8),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    ),
  );
}

IconData _categoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('sport')) return Icons.sports_soccer;
  if (value.contains('movie') || value.contains('film')) return Icons.movie;
  if (value.contains('music')) return Icons.music_note;
  if (value.contains('news')) return Icons.newspaper;
  if (value.contains('kid')) return Icons.child_care;
  if (value.contains('life')) return Icons.spa;
  if (value.contains('document')) return Icons.star;
  return Icons.tv;
}
