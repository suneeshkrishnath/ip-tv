import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/core/constants/initial_playlist_sources.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/utils/mask_url.dart';
import 'package:ip_tv/shared/widgets/error_view.dart';

DioException _dio(DioExceptionType type, [int? status]) => DioException(
  requestOptions: RequestOptions(path: 'https://secret.test/list.m3u'),
  type: type,
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: status,
        ),
);

void main() {
  group('NetworkFailure.fromDio', () {
    test('explains timeouts, offline and TLS errors with codes', () {
      final timeout = NetworkFailure.fromDio(
        'Unable to download Tamil',
        _dio(DioExceptionType.receiveTimeout),
      );
      expect(timeout.code, 'NET-TIMEOUT');
      expect(timeout.message, contains('took too long'));

      expect(
        NetworkFailure.fromDio('x', _dio(DioExceptionType.connectionError)).code,
        'NET-OFFLINE',
      );
      expect(
        NetworkFailure.fromDio('x', _dio(DioExceptionType.badCertificate)).code,
        'NET-TLS',
      );
    });

    test('maps HTTP statuses to readable reasons', () {
      NetworkFailure http(int status) => NetworkFailure.fromDio(
        'Unable to download Tamil',
        _dio(DioExceptionType.badResponse, status),
      );

      expect(http(404).code, 'NET-HTTP-404');
      expect(http(404).message, contains('not found'));
      expect(http(403).message, contains('denied'));
      expect(http(503).message, contains('server has a problem'));
      expect(http(418).message, contains('unexpected'));
    });

    test('never leaks the playlist URL into the message', () {
      final failure = NetworkFailure.fromDio(
        'Unable to download Tamil',
        _dio(DioExceptionType.connectionError),
      );
      expect(failure.userMessage, isNot(contains('secret.test')));
    });
  });

  test('every failure type carries a code in its user message', () {
    const failures = <AppFailure>[
      PlaylistParsingFailure('a'),
      PlaylistValidationFailure('a'),
      CacheFailure('a'),
      EpgFailure('a'),
      PlaybackFailure('a'),
      UnknownFailure('a'),
      NetworkFailure('a'),
    ];
    for (final failure in failures) {
      expect(failure.code, isNotEmpty);
      expect(failure.userMessage, 'a (Error code: ${failure.code})');
    }
  });

  testWidgets('ErrorView shows the error code', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ErrorView(error: NetworkFailure('Offline', code: 'NET-OFFLINE')),
      ),
    );

    expect(find.text('Offline (Error code: NET-OFFLINE)'), findsOneWidget);
  });

  group('maskUrl', () {
    test('keeps only the host', () {
      expect(
        maskUrl('https://example.test/private/token.m3u?key=1'),
        'https://example.test/••••••••',
      );
    });

    test('fully hides unparsable values', () {
      expect(maskUrl('not a url'), '••••••••');
    });
  });

  test('built-in sources include the language and sports playlists', () {
    final byId = {for (final s in initialPlaylistSources) s.id: s.url};

    expect(byId['tamil'], 'https://iptv-org.github.io/iptv/languages/tam.m3u');
    expect(byId['kannada'], 'https://iptv-org.github.io/iptv/languages/kan.m3u');
    expect(byId['telugu'], 'https://iptv-org.github.io/iptv/languages/tel.m3u');
    expect(byId['hindi'], 'https://iptv-org.github.io/iptv/languages/hin.m3u');
    expect(byId['english'], 'https://iptv-org.github.io/iptv/languages/eng.m3u');
    expect(
      byId['sports'],
      'https://iptv-org.github.io/iptv/categories/sports.m3u',
    );
    expect(initialPlaylistSources.map((s) => s.id).toSet(),
        hasLength(initialPlaylistSources.length));
  });
}
