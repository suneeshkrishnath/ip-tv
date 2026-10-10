import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/player/presentation/player_providers.dart';
import 'package:ip_tv/features/player/presentation/player_screen.dart';
import 'package:ip_tv/features/player/presentation/player_session.dart';

void main() {
  const channel = Channel(
    id: 'test-channel',
    name: 'Test Channel',
    streamUrl: 'https://example.test/live.m3u8',
  );

  testWidgets('opens the selected stream and exposes playback controls', (
    tester,
  ) async {
    final session = _FakePlayerSession();
    await tester.pumpWidget(_playerApp(channel, session));
    await tester.pumpAndSettle();

    expect(session.openedUrl, channel.streamUrl);
    expect(find.byTooltip('Play'), findsOneWidget);
    await tester.tap(find.byTooltip('Play'));
    expect(session.playOrPauseCount, 1);
  });

  testWidgets('shows an error state when the stream fails', (tester) async {
    final session = _FakePlayerSession();
    await tester.pumpWidget(_playerApp(channel, session));
    await tester.pumpAndSettle();

    session.errorController.add('decoder error');
    await tester.pump();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Unable to play this stream.'), findsOneWidget);
  });
}

Widget _playerApp(Channel channel, _FakePlayerSession session) {
  return ProviderScope(
    overrides: [
      playerSessionFactoryProvider.overrideWithValue(
        _FakePlayerSessionFactory(session),
      ),
    ],
    child: MaterialApp(home: PlayerScreen(channel: channel)),
  );
}

class _FakePlayerSessionFactory implements PlayerSessionFactory {
  const _FakePlayerSessionFactory(this.session);

  final _FakePlayerSession session;

  @override
  PlayerSession create() => session;
}

class _FakePlayerSession implements PlayerSession {
  final errorController = StreamController<String>.broadcast(sync: true);
  String? openedUrl;
  int playOrPauseCount = 0;

  @override
  Stream<bool> get playing => Stream.value(false);

  @override
  Stream<bool> get buffering => Stream.value(false);

  @override
  Stream<double> get volume => Stream.value(70);

  @override
  Stream<String> get errors => errorController.stream;

  @override
  Widget videoView() => const ColoredBox(color: Colors.black);

  @override
  Future<void> open(String streamUrl) async {
    openedUrl = streamUrl;
  }

  @override
  Future<void> playOrPause() async {
    playOrPauseCount++;
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() => errorController.close();
}