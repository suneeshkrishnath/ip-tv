import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/epg/domain/models/program.dart';
import 'package:ip_tv/features/favorites/domain/models/favorite.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';

void main() {
  group('domain model serialization', () {
    test('channel round-trips through JSON without losing its stream URL', () {
      const channel = Channel(
        id: 'channel-1',
        name: 'Example News',
        streamUrl: 'https://example.test/live.m3u8',
        category: 'News',
        logoUrl: 'https://example.test/logo.png',
        epgId: 'example.news',
      );

      expect(Channel.fromJson(channel.toJson()), channel);
    });

    test('playlist round-trips nested channels', () {
      final playlist = Playlist(
        id: 'playlist-1',
        name: 'Test list',
        sourceUrl: 'https://example.test/list.m3u',
        channels: const [
          Channel(
            id: 'channel-1',
            name: 'Example',
            streamUrl: 'https://example.test/live.m3u8',
          ),
        ],
        lastUpdated: DateTime.utc(2026, 10, 10),
      );

      expect(Playlist.fromJson(playlist.toJson()), playlist);
    });

    test('favorite and program preserve their timestamps', () {
      final addedAt = DateTime.utc(2026, 10, 10, 12);
      final favorite = Favorite(channelId: 'channel-1', addedAt: addedAt);
      final program = Program(
        id: 'program-1',
        channelId: 'channel-1',
        title: 'Evening news',
        start: addedAt,
        end: DateTime.utc(2026, 10, 10, 13),
      );

      expect(Favorite.fromJson(favorite.toJson()), favorite);
      expect(Program.fromJson(program.toJson()), program);
    });
  });
}