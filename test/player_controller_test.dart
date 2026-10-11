import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/player/application/player_controller.dart';
import 'package:ip_tv/features/player/domain/player_engine.dart';

const _channel = Channel(
  id: 'news',
  name: 'Example News',
  streamUrl: 'https://example.test/live.m3u8',
);

class FakePlayerEngine implements PlayerEngine {
  final playing = StreamController<bool>.broadcast();
  final buffering = StreamController<bool>.broadcast();
  final errors = StreamController<String>.broadcast();
  final openedUrls = <String>[];
  bool disposed = false;
  bool throwOnOpen = false;
  int toggles = 0;

  @override
  Stream<bool> get playingStream => playing.stream;

  @override
  Stream<bool> get bufferingStream => buffering.stream;

  @override
  Stream<String> get errorStream => errors.stream;

  @override
  Future<void> open(String url) async {
    openedUrls.add(url);
    if (throwOnOpen) throw StateError('boom');
  }

  @override
  Future<void> playOrPause() async => toggles++;

  @override
  Widget buildVideo() => const SizedBox();

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  late FakePlayerEngine engine;
  late ProviderContainer container;

  setUp(() {
    engine = FakePlayerEngine();
    container = ProviderContainer(
      overrides: [playerEngineFactoryProvider.overrideWithValue(() => engine)],
    );
    addTearDown(container.dispose);
  });

  PlayerState read() => container.read(playerControllerProvider(_channel));

  test('opens the channel stream and starts in loading state', () async {
    final subscription =
        container.listen(playerControllerProvider(_channel), (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);

    expect(engine.openedUrls, [_channel.streamUrl]);
    expect(read().status, PlayerStatus.loading);
  });

  test('tracks buffering, playing and paused states', () async {
    final subscription =
        container.listen(playerControllerProvider(_channel), (_, _) {});
    addTearDown(subscription.close);

    engine.buffering.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(read().status, PlayerStatus.loading);

    engine.buffering.add(false);
    engine.playing.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(read().status, PlayerStatus.playing);

    engine.playing.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(read().status, PlayerStatus.paused);
  });

  test('reports stream errors and retry reopens the stream', () async {
    final subscription =
        container.listen(playerControllerProvider(_channel), (_, _) {});
    addTearDown(subscription.close);

    engine.errors.add('Failed to open');
    await Future<void>.delayed(Duration.zero);
    expect(read().status, PlayerStatus.error);
    expect(read().errorMessage, 'Failed to open');

    await container.read(playerControllerProvider(_channel).notifier).retry();
    expect(read().status, PlayerStatus.loading);
    expect(engine.openedUrls, hasLength(2));
  });

  test('reports an error when opening throws', () async {
    engine.throwOnOpen = true;
    final subscription =
        container.listen(playerControllerProvider(_channel), (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);

    expect(read().status, PlayerStatus.error);
  });

  test('play/pause is delegated and engine is disposed with the provider',
      () async {
    final subscription =
        container.listen(playerControllerProvider(_channel), (_, _) {});
    await container
        .read(playerControllerProvider(_channel).notifier)
        .playOrPause();
    expect(engine.toggles, 1);

    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(engine.disposed, isTrue);
  });
}
