import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/core/constants/initial_playlist_sources.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/epg/application/epg_providers.dart';
import 'package:ip_tv/features/epg/data/datasources/epg_remote_data_source.dart';
import 'package:ip_tv/features/epg/data/parsers/xmltv_parser.dart';
import 'package:ip_tv/features/epg/data/repositories/epg_repository_impl.dart';
import 'package:ip_tv/features/epg/domain/models/epg_guide.dart';
import 'package:ip_tv/features/epg/domain/models/program.dart';
import 'package:ip_tv/features/epg/presentation/program_panel.dart';

const _xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="News.in"><display-name>News</display-name></channel>
  <programme start="20261011100000 +0000" stop="20261011110000 +0000" channel="News.in">
    <title>Morning News</title><desc>Headlines</desc>
  </programme>
  <programme start="20261011110000 +0000" stop="20261011120000 +0000" channel="News.in">
    <title>Weather</title>
  </programme>
  <programme start="20261011120000 +0000" stop="20261011130000 +0000" channel="Other.in">
    <title>Other show</title>
  </programme>
</tv>
''';

final _now = DateTime.utc(2026, 10, 11, 10, 30);

void main() {
  group('XmltvParser', () {
    test('parses programmes and groups them by normalized channel', () {
      final guide = XmltvParser().parse(_xml);

      final current = guide.currentProgram('News.in@SD', _now)!;
      expect(current.title, 'Morning News');
      expect(current.description, 'Headlines');
      expect(current.start, DateTime.utc(2026, 10, 11, 10));
      expect(guide.nextProgram('news.in', _now)!.title, 'Weather');
      expect(guide.currentProgram('Other.in', _now), isNull);
    });

    test('filters to the requested channels', () {
      final guide = XmltvParser().parse(_xml, channelIds: {'News.in@HD'});

      expect(guide.scheduleFor('Other.in', _now), isEmpty);
      expect(guide.scheduleFor('News.in', _now), hasLength(2));
    });

    test('applies time zone offsets and treats a missing offset as UTC', () {
      final guide = XmltvParser().parse('''
<tv>
  <programme start="20261011120000 +0530" stop="20261011130000 +0530" channel="a"><title>A</title></programme>
  <programme start="20261011120000" stop="20261011130000" channel="b"><title>B</title></programme>
</tv>''');

      expect(
        guide.scheduleFor('a', DateTime.utc(2026)).single.start,
        DateTime.utc(2026, 10, 11, 6, 30),
      );
      expect(
        guide.scheduleFor('b', DateTime.utc(2026)).single.start,
        DateTime.utc(2026, 10, 11, 12),
      );
    });

    test('skips invalid programmes', () {
      final guide = XmltvParser().parse('''
<tv>
  <programme start="bad" stop="20261011130000" channel="a"><title>Bad time</title></programme>
  <programme start="20261011130000" stop="20261011120000" channel="a"><title>Ends first</title></programme>
  <programme start="20261011120000" stop="20261011130000" channel="a"><title> </title></programme>
  <programme start="20261011120000" stop="20261011130000"><title>No channel</title></programme>
  <programme start="20261011120000" stop="20261011130000" channel="a"><title>Good</title></programme>
</tv>''');

      expect(
        guide.scheduleFor('a', DateTime.utc(2026)).map((p) => p.title),
        ['Good'],
      );
    });

    test('rejects malformed XML and non-XMLTV documents', () {
      expect(() => XmltvParser().parse('<tv>'), throwsFormatException);
      expect(() => XmltvParser().parse('<html/>'), throwsFormatException);
    });
  });

  group('EpgGuide', () {
    final guide = EpgGuide({
      'a': [
        Program(
          id: '2',
          channelId: 'a',
          title: 'Second',
          start: DateTime.utc(2026, 10, 11, 11),
          end: DateTime.utc(2026, 10, 11, 12),
        ),
        Program(
          id: '1',
          channelId: 'a',
          title: 'First',
          start: DateTime.utc(2026, 10, 11, 10),
          end: DateTime.utc(2026, 10, 11, 11),
        ),
      ],
    });

    test('sorts programmes and handles boundaries', () {
      expect(guide.currentProgram('a', DateTime.utc(2026, 10, 11, 10))!.title,
          'First');
      expect(guide.currentProgram('a', DateTime.utc(2026, 10, 11, 11))!.title,
          'Second');
      expect(guide.currentProgram('a', DateTime.utc(2026, 10, 11, 12)), isNull);
      expect(guide.nextProgram('a', DateTime.utc(2026, 10, 11, 10))!.title,
          'Second');
      expect(guide.nextProgram('a', DateTime.utc(2026, 10, 11, 11)), isNull);
      expect(guide.scheduleFor('a', DateTime.utc(2026, 10, 11, 11, 30)),
          hasLength(1));
      expect(guide.currentProgram(null, _now), isNull);
    });

    test('round-trips through JSON', () {
      final restored = EpgGuide.fromJson(guide.toJson());
      expect(restored.scheduleFor('a', DateTime.utc(2026)), hasLength(2));
    });
  });

  group('EpgRepositoryImpl', () {
    test('downloads and parses a guide', () async {
      final repository = EpgRepositoryImpl(
        remoteDataSource: _FakeRemote(xml: _xml),
        parse: (xml, ids, at) async =>
            XmltvParser().parse(xml, channelIds: ids, fetchedAt: at),
        clock: () => _now,
      );

      final result = await repository.loadGuide(
        'https://example.test/guide.xml',
        channelIds: {'News.in'},
      );

      final guide = (result as Success<EpgGuide>).value;
      expect(guide.fetchedAt, _now);
      expect(guide.currentProgram('News.in', _now), isNotNull);
    });

    test('maps download and parse errors to guide failures', () async {
      for (final remote in [
        _FakeRemote(error: DioException(requestOptions: RequestOptions())),
        _FakeRemote(xml: 'not xml'),
      ]) {
        final repository = EpgRepositoryImpl(
          remoteDataSource: remote,
          parse: (xml, ids, at) async => XmltvParser().parse(xml),
        );
        final result = await repository.loadGuide('https://example.test/g');
        expect((result as FailureResult<EpgGuide>).failure, isA<EpgFailure>());
      }
    });
  });

  testWidgets('ProgramPanel shows now/next and opens the schedule',
      (tester) async {
    final guide = XmltvParser().parse(_xml);
    const channel = Channel(
      id: 'news',
      name: 'Example News',
      streamUrl: 'https://example.test/live.m3u8',
      epgId: 'News.in@SD',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [epgGuideProvider.overrideWith((ref) async => guide)],
        child: MaterialApp(
          home: Scaffold(
            body: ProgramPanel(channel: channel, clock: () => _now),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Now: Morning News'), findsOneWidget);
    expect(find.textContaining('Weather'), findsOneWidget);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Example News schedule'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('ProgramPanel is hidden without a guide', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [epgGuideProvider.overrideWith((ref) async => null)],
        child: const MaterialApp(
          home: Scaffold(
            body: ProgramPanel(
              channel: Channel(id: 'x', name: 'X', streamUrl: 'https://x.test'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Schedule'), findsNothing);
  });

  test('built-in sources have no guide URL', () {
    expect(initialPlaylistSources.every((s) => s.epgUrl == null), isTrue);
  });
}

class _FakeRemote implements EpgRemoteDataSource {
  _FakeRemote({this.xml, this.error});

  final String? xml;
  final Object? error;

  @override
  Future<String> fetch(String epgUrl) async {
    if (error case final Object error) throw error;
    return xml!;
  }
}
