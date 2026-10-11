import 'package:flutter/widgets.dart';

/// Abstraction over the video backend so playback logic can be tested.
abstract interface class PlayerEngine {
  Stream<bool> get playingStream;

  Stream<bool> get bufferingStream;

  Stream<String> get errorStream;

  Future<void> open(String url);

  Future<void> playOrPause();

  Widget buildVideo();

  Future<void> dispose();
}
