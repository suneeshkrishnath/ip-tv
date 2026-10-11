import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/features/playlists/data/parsers/m3u_parser.dart';
import 'package:ip_tv/features/playlists/data/validators/playlist_validator.dart';

void main() {
  const playlist = '''
#EXTM3U
#EXTINF:-1 tvg-id="news.one" tvg-logo="https://example.test/logo.png" group-title="News",Example News
https://stream.example.test/live.m3u8?token=abc
#EXTINF:-1 group-title="News",Example News
https://stream.example.test/second.m3u8
''';

  group('M3uParser', () {
    test('parses metadata and preserves stream URLs', () {
      final channels = M3uParser().parse(playlist);

      expect(channels, hasLength(2));
      expect(channels.first.id, 'news.one');
      expect(channels.first.name, 'Example News');
      expect(channels.first.category, 'News');
      expect(channels.first.logoUrl, 'https://example.test/logo.png');
      expect(
        channels.first.streamUrl,
        'https://stream.example.test/live.m3u8?token=abc',
      );
      expect(channels.last.id, 'example-news');
    });

    test('accepts a header with attributes', () {
      final channels = M3uParser().parse(
        '#EXTM3U x-tvg-url="https://example.test/epg.xml"\n'
        '#EXTINF:-1,Example\nhttps://example.test/live.m3u8\n',
      );

      expect(channels, hasLength(1));
    });

    test('rejects content without an M3U header', () {
      expect(
        () => M3uParser().parse('https://example.test/live.m3u8'),
        throwsA(isA<M3uParseException>()),
      );
    });

    test('rejects an empty playlist', () {
      expect(
        () => M3uParser().parse('#EXTM3U\n'),
        throwsA(isA<M3uParseException>()),
      );
    });
  });

  group('PlaylistValidator', () {
    test('rejects non-network stream schemes', () {
      final channels = M3uParser().parse(
        '#EXTM3U\n#EXTINF:-1,Local file\nfile:///video.mp4\n',
      );

      expect(
        () => PlaylistValidator().validate(channels),
        throwsA(isA<PlaylistValidationException>()),
      );
    });

    test('accepts the parsed remote streams', () {
      expect(
        () => PlaylistValidator().validate(M3uParser().parse(playlist)),
        returnsNormally,
      );
    });
  });
}