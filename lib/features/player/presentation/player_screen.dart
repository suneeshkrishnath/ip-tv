import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/application/favorites_providers.dart';
import 'package:ip_tv/features/player/application/player_controller.dart';
import 'package:ip_tv/shared/widgets/error_view.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({required this.channel, super.key});

  final Channel channel;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _fullscreen = false;

  @override
  void dispose() {
    _applyFullscreen(false);
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    _applyFullscreen(_fullscreen);
  }

  void _applyFullscreen(bool enabled) {
    SystemChrome.setEnabledSystemUIMode(
      enabled ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    SystemChrome.setPreferredOrientations(
      enabled
          ? [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : DeviceOrientation.values,
    );
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    final provider = playerControllerProvider(channel);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final isFavorite = ref.watch(isFavoriteProvider(channel.id));
    final isPlaying = state.status == PlayerStatus.playing;

    return PopScope(
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _toggleFullscreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _fullscreen
            ? null
            : AppBar(
                title: Text(channel.name),
                actions: [
                  IconButton(
                    tooltip: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(channel),
                  ),
                ],
              ),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              controller.engine.buildVideo(),
              if (state.status == PlayerStatus.loading)
                const Center(child: CircularProgressIndicator()),
              if (state.status == PlayerStatus.error)
                ColoredBox(
                  color: Colors.black,
                  child: ErrorView(
                    error: UnknownFailure(
                      state.errorMessage ?? 'Playback failed.',
                    ),
                    onRetry: controller.retry,
                  ),
                )
              else
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        onPressed: controller.playOrPause,
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        tooltip:
                            _fullscreen ? 'Exit full screen' : 'Full screen',
                        onPressed: _toggleFullscreen,
                        icon: Icon(
                          _fullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
