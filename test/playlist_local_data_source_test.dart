import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/playlists/data/datasources/playlist_local_data_source.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';

void main() {
  late Directory directory;
  late Box<String> box;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('iptv_hive_test_');
    Hive.init(directory.path);
    box = await Hive.openBox<String>('playlists_test');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('caches and restores nested channel data', () async {
    final dataSource = HivePlaylistLocalDataSource(box);
    const playlist = Playlist(
      id: 'playlist-1',
      name: 'Test playlist',
      sourceUrl: 'https://example.test/list.m3u',
      channels: [
        Channel(
          id: 'channel-1',
          name: 'Example channel',
          streamUrl: 'https://example.test/live.m3u8',
        ),
      ],
    );

    await dataSource.cache(playlist);

    expect(await dataSource.get(playlist.id), playlist);
    await dataSource.remove(playlist.id);
    expect(await dataSource.get(playlist.id), isNull);
  });
}