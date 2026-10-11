import 'package:flutter/widgets.dart';
import 'package:ip_tv/core/logging/app_logger.dart';
import 'package:ip_tv/features/player/domain/player_engine.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaKitPlayerEngine implements PlayerEngine {
  MediaKitPlayerEngine() {
    _controller = VideoController(_player);
    _player.stream.log.listen((log) => appLogger.d('mpv ${log.prefix}: ${log.text}'));
    _player.stream.error.listen((error) => appLogger.e('mpv error: $error'));
  }

  final Player _player = Player();
  late final VideoController _controller;

  @override
  Stream<bool> get playingStream => _player.stream.playing;

  @override
  Stream<bool> get bufferingStream => _player.stream.buffering;

  @override
  Stream<String> get errorStream => _player.stream.error;

  @override
  Future<void> open(String url) => _player.open(Media(url));

  @override
  Future<void> playOrPause() => _player.playOrPause();

  @override
  Widget buildVideo() =>
      Video(controller: _controller, controls: NoVideoControls);

  @override
  Future<void> dispose() => _player.dispose();
}
