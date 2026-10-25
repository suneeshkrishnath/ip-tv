import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ip_tv/features/channels/application/channel_providers.dart';
import 'package:ip_tv/features/channels/presentation/channel_card.dart';
import 'package:ip_tv/features/epg/application/epg_providers.dart';
import 'package:ip_tv/features/favorites/application/favorites_providers.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/shared/widgets/app_search_bar.dart';
import 'package:ip_tv/shared/widgets/empty_state_view.dart';
import 'package:ip_tv/shared/widgets/error_view.dart';
import 'package:ip_tv/shared/widgets/loading_widget.dart';

class CategoryChannelsScreen extends ConsumerStatefulWidget {
  const CategoryChannelsScreen({required this.category, super.key});

  final String category;

  @override
  ConsumerState<CategoryChannelsScreen> createState() =>
      _CategoryChannelsScreenState();
}

class _CategoryChannelsScreenState
    extends ConsumerState<CategoryChannelsScreen> {
  late String? _category = widget.category == 'all' ? null : widget.category;
  String _query = '';
  bool _searchOpen = false;
  bool _loadRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  Future<void> _loadIfNeeded() async {
    if (_loadRequested || !mounted) return;
    final source = ref.read(selectedPlaylistSourceProvider);
    var playlist = ref.read(currentPlaylistProvider).value;
    if (playlist?.id != source.id) {
      await ref.read(currentPlaylistProvider.notifier).showCached(source);
      playlist = ref.read(currentPlaylistProvider).value;
    }
    if (playlist == null && mounted) {
      _loadRequested = true;
      await ref.read(currentPlaylistProvider.notifier).loadSource(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(currentPlaylistProvider);
    final source = ref.watch(selectedPlaylistSourceProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_category ?? source.name),
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search channels',
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) _query = '';
            }),
          ),
          IconButton(
            tooltip: 'Filter categories',
            icon: const Icon(Icons.filter_list),
            onPressed: _showCategories,
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const LoadingWidget(label: 'Loading channels'),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () =>
                ref.read(currentPlaylistProvider.notifier).loadSource(source),
          ),
          data: (playlist) => playlist == null
              ? EmptyStateView(
                  icon: Icons.live_tv,
                  title: 'No channels loaded',
                  message: 'Load this playlist to browse its channels.',
                  actionLabel: 'Load channels',
                  onAction: () => ref
                      .read(currentPlaylistProvider.notifier)
                      .loadSource(source),
                )
              : _channelList(context, ref, playlist),
        ),
      ),
    );
  }

  Widget _channelList(BuildContext context, WidgetRef ref, Playlist playlist) {
    final categories =
        playlist.channels
            .map((channel) => channel.category)
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final channels = filterChannels(
      playlist.channels,
      query: _query,
      category: _category,
    );
    final guide = ref.watch(epgGuideProvider).value;

    return Column(
      children: [
        if (ref.watch(playlistOfflineProvider))
          MaterialBanner(
            leading: const Icon(Icons.cloud_off),
            content: const Text('Could not refresh. Showing saved channels.'),
            actions: [
              TextButton(
                onPressed: () => ref
                    .read(currentPlaylistProvider.notifier)
                    .loadSource(ref.read(selectedPlaylistSourceProvider)),
                child: const Text('Retry'),
              ),
            ],
          ),
        if (_searchOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: AppSearchBar(
              query: _query,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('All', null),
                for (final category in categories) _chip(category, category),
              ],
            ),
          ),
        Expanded(
          child: channels.isEmpty
              ? const EmptyStateView(
                  icon: Icons.search_off,
                  title: 'No channels found',
                  message: 'Try another category or search.',
                )
              : ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return ChannelCard(
                      channel: channel,
                      nowPlaying: guide
                          ?.currentProgram(channel.epgId, DateTime.now())
                          ?.title,
                      isFavorite: ref.watch(isFavoriteProvider(channel.id)),
                      onFavoriteToggle: () =>
                          ref.read(favoritesProvider.notifier).toggle(channel),
                      onTap: () => context.pushNamed('player', extra: channel),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: _category == value,
      onSelected: (_) => setState(() => _category = value),
    ),
  );

  Future<void> _showCategories() async {
    final playlist = ref.read(currentPlaylistProvider).value;
    if (playlist == null) return;
    final categories =
        playlist.channels
            .map((channel) => channel.category)
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final category in categories)
              ListTile(
                title: Text(category),
                trailing: category == _category
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(category),
              ),
          ],
        ),
      ),
    );
    if (choice != null && mounted) setState(() => _category = choice);
  }
}
