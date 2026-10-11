import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ip_tv/features/channels/presentation/channel_card.dart';
import 'package:ip_tv/features/favorites/application/favorites_providers.dart';
import 'package:ip_tv/features/history/application/history_providers.dart';
import 'package:ip_tv/shared/widgets/empty_state_view.dart';
import 'package:ip_tv/shared/widgets/error_view.dart';
import 'package:ip_tv/shared/widgets/loading_widget.dart';

class RecentlyWatchedScreen extends ConsumerWidget {
  const RecentlyWatchedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentlyWatchedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recently watched')),
      body: SafeArea(
        child: recent.when(
          loading: () => const LoadingWidget(label: 'Loading history'),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(recentlyWatchedProvider),
          ),
          data: (channels) {
            if (channels.isEmpty) {
              return const EmptyStateView(
                icon: Icons.history,
                title: 'Nothing watched yet',
                message: 'Channels you play will appear here.',
              );
            }
            return ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return ChannelCard(
                  channel: channel,
                  isFavorite: ref.watch(isFavoriteProvider(channel.id)),
                  onFavoriteToggle: () =>
                      ref.read(favoritesProvider.notifier).toggle(channel),
                  onTap: () => context.pushNamed('player', extra: channel),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
