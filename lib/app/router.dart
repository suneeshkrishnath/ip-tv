import 'package:go_router/go_router.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/channels/presentation/home_screen.dart';
import 'package:ip_tv/features/disclaimer/presentation/disclaimer_gate.dart';
import 'package:ip_tv/features/favorites/presentation/favorites_screen.dart';
import 'package:ip_tv/features/history/presentation/recently_watched_screen.dart';
import 'package:ip_tv/features/player/presentation/player_screen.dart';
import 'package:ip_tv/features/playlists/presentation/manage_playlists_screen.dart';
import 'package:ip_tv/shared/widgets/error_view.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) =>
          const DisclaimerGate(child: HomeScreen()),
    ),
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/playlists',
      name: 'playlists',
      builder: (context, state) => const ManagePlaylistsScreen(),
    ),
    GoRoute(
      path: '/recent',
      name: 'recent',
      builder: (context, state) => const RecentlyWatchedScreen(),
    ),
    GoRoute(
      path: '/player',
      name: 'player',
      builder: (context, state) {
        final channel = state.extra;
        if (channel is! Channel) {
          return const ErrorView(error: 'Missing channel information.');
        }
        return PlayerScreen(channel: channel);
      },
    ),
  ],
);