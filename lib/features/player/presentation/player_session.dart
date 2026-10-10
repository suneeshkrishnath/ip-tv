import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

abstract interface class PlayerSession {
  Stream<bool> get playing;

  Stream<bool> get buffering;

  Stream<double> get volume;

  Stream<String> get errors;

  Widget videoView();

  Future<void> open(String streamUrl);

  Future<void> playOrPause();

  Future<void> setVolume(double volume);

  Future<void> dispose();
}

abstract interface class PlayerSessionFactory {
  PlayerSession create();
}

class MediaKitPlayerSessionFactory implements PlayerSessionFactory {
  const MediaKitPlayerSessionFactory();

  @override
  PlayerSession create() => MediaKitPlayerSession();
}

class MediaKitPlayerSession implements PlayerSession {
  MediaKitPlayerSession() : _player = Player() {
    _controller = VideoController(_player);
  }

  final Player _player;
  late final VideoController _controller;

  @override
  Stream<bool> get playing => _player.stream.playing;

  @override
  Stream<bool> get buffering => _player.stream.buffering;

  @override
  Stream<double> get volume => _player.stream.volume;

  @override
  Stream<String> get errors => _player.stream.error;

  @override
  Widget videoView() => Video(
        controller: _controller,
        controls: NoVideoControls,
      );

  @override
  Future<void> open(String streamUrl) => _player.open(Media(streamUrl));

  @override
  Future<void> playOrPause() => _player.playOrPause();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> dispose() => _player.dispose();
}