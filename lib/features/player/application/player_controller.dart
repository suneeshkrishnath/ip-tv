import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/player/data/media_kit_player_engine.dart';
import 'package:ip_tv/features/player/domain/player_engine.dart';

enum PlayerStatus { loading, playing, paused, error }

class PlayerState {
  const PlayerState({this.status = PlayerStatus.loading, this.errorMessage});

  final PlayerStatus status;
  final String? errorMessage;
}

final playerEngineFactoryProvider = Provider<PlayerEngine Function()>(
  (ref) => MediaKitPlayerEngine.new,
);

final playerControllerProvider = NotifierProvider.autoDispose
    .family<PlayerController, PlayerState, Channel>(PlayerController.new);

class PlayerController extends Notifier<PlayerState> {
  PlayerController(this.channel);

  final Channel channel;
  late final PlayerEngine engine;
  bool _playing = false;
  bool _started = false;
  bool _buffering = false;
  String? _error;

  @override
  PlayerState build() {
    engine = ref.read(playerEngineFactoryProvider)();
    final subscriptions = [
      engine.playingStream.listen((value) {
        _playing = value;
        _publish();
      }),
      engine.bufferingStream.listen((value) {
        _buffering = value;
        _publish();
      }),
      engine.errorStream.listen((message) {
        _error = message;
        _publish();
      }),
    ];
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
      unawaited(engine.dispose());
    });
    unawaited(_open());
    return const PlayerState();
  }

  Future<void> retry() {
    _error = null;
    _started = false;
    state = const PlayerState();
    return _open();
  }

  Future<void> playOrPause() => engine.playOrPause();

  Future<void> _open() async {
    try {
      await engine.open(channel.streamUrl);
    } on Object {
      _error = 'Unable to start this stream.';
      _publish();
    }
  }

  void _publish() {
    if (_playing) _started = true;
    final error = _error;
    state = error != null
        ? PlayerState(status: PlayerStatus.error, errorMessage: error)
        : PlayerState(
            status: _buffering || !(_playing || _started)
                ? PlayerStatus.loading
                : _playing
                    ? PlayerStatus.playing
                    : PlayerStatus.paused,
          );
  }
}
