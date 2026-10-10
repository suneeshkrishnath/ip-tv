import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/logging/app_logger.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/player/presentation/player_providers.dart';
import 'package:ip_tv/features/player/presentation/player_session.dart';
import 'package:ip_tv/shared/widgets/error_view.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({required this.channel, super.key});

  final Channel channel;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final PlayerSession _session;
  StreamSubscription<String>? _errorSubscription;
  String? _errorMessage;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _session = ref.read(playerSessionFactoryProvider).create();
    _errorSubscription = _session.errors.listen((message) {
      if (mounted) setState(() => _errorMessage = message);
    });
    _openStream();
  }

  Future<void> _openStream() async {
    try {
      await _session.open(widget.channel.streamUrl);
    } catch (error, stackTrace) {
      appLogger.e('Stream startup failed', error: error, stackTrace: stackTrace);
      if (mounted) setState(() => _errorMessage = 'Unable to play this stream.');
    }
  }

  Future<void> _toggleFullscreen() async {
    final entering = !_isFullscreen;
    try {
      await SystemChrome.setPreferredOrientations(
        entering
            ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
            : const [],
      );
      await SystemChrome.setEnabledSystemUIMode(
        entering ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
      if (mounted) setState(() => _isFullscreen = entering);
    } catch (error, stackTrace) {
      appLogger.e('Fullscreen change failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _playOrPause() async {
    try {
      await _session.playOrPause();
    } catch (error, stackTrace) {
      appLogger.e('Playback control failed', error: error, stackTrace: stackTrace);
      if (mounted) setState(() => _errorMessage = 'Playback control failed.');
    }
  }

  Future<void> _setVolume(double volume) async {
    try {
      await _session.setVolume(volume);
    } catch (error, stackTrace) {
      appLogger.e('Volume change failed', error: error, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    unawaited(_session.dispose());
    if (_isFullscreen) {
      unawaited(SystemChrome.setPreferredOrientations(const []));
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen ? null : AppBar(title: Text(widget.channel.name)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _session.videoView(),
                      StreamBuilder<bool>(
                        stream: _session.buffering,
                        initialData: true,
                        builder: (context, snapshot) {
                          if (snapshot.data != true || _errorMessage != null) {
                            return const SizedBox.shrink();
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                      if (_errorMessage != null)
                        ErrorView(
                          error: const UnknownFailure(
                            'Unable to play this stream.',
                          ),
                          onRetry: _openStream,
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildControls(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isFullscreen)
              ListTile(
                title: Text(
                  widget.channel.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: widget.channel.category.isEmpty
                    ? null
                    : Text(
                        widget.channel.category,
                        style: const TextStyle(color: Colors.white70),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          StreamBuilder<bool>(
            stream: _session.playing,
            initialData: false,
            builder: (context, snapshot) => IconButton(
              tooltip: snapshot.data == true ? 'Pause' : 'Play',
              color: Colors.white,
              onPressed: _playOrPause,
              icon: Icon(
                snapshot.data == true ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
          const Icon(Icons.volume_up, color: Colors.white),
          Expanded(
            child: StreamBuilder<double>(
              stream: _session.volume,
              initialData: 100,
              builder: (context, snapshot) => Slider(
                value: (snapshot.data ?? 100).clamp(0, 100),
                min: 0,
                max: 100,
                onChanged: _setVolume,
              ),
            ),
          ),
          IconButton(
            tooltip: _isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
            color: Colors.white,
            onPressed: _toggleFullscreen,
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            ),
          ),
        ],
      ),
    );
  }
}