import 'package:ip_tv/features/epg/domain/models/epg_guide.dart';
import 'package:ip_tv/features/epg/domain/models/program.dart';
import 'package:xml/xml.dart';

class XmltvParser {
  static final _timePattern = RegExp(
    r'^(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?(\d{2})?\s*([+-])?(\d{2})?(\d{2})?$',
  );

  /// Parses XMLTV; when [channelIds] is given only matching channels are kept.
  EpgGuide parse(String xml, {Set<String>? channelIds, DateTime? fetchedAt}) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException catch (error) {
      throw FormatException('Invalid XMLTV: ${error.message}');
    }
    final root = document.rootElement;
    if (root.name.local != 'tv') {
      throw const FormatException('XMLTV root element must be <tv>.');
    }

    final wanted = channelIds?.map(EpgGuide.normalizeId).toSet();
    final programs = <String, List<Program>>{};
    for (final element in root.findElements('programme')) {
      final rawChannel = element.getAttribute('channel');
      final start = _parseTime(element.getAttribute('start'));
      final end = _parseTime(element.getAttribute('stop'));
      final title = element.getElement('title')?.innerText.trim();
      if (rawChannel == null ||
          start == null ||
          end == null ||
          !end.isAfter(start) ||
          title == null ||
          title.isEmpty) {
        continue;
      }
      final channel = EpgGuide.normalizeId(rawChannel);
      if (wanted != null && !wanted.contains(channel)) continue;

      final description = element.getElement('desc')?.innerText.trim();
      programs.putIfAbsent(channel, () => []).add(
        Program(
          id: '$channel-${start.millisecondsSinceEpoch}',
          channelId: channel,
          title: title,
          start: start,
          end: end,
          description: description == null || description.isEmpty
              ? null
              : description,
        ),
      );
    }
    return EpgGuide(programs, fetchedAt: fetchedAt);
  }

  /// Handles `yyyyMMddHHmmss +hhmm`; a missing offset is treated as UTC.
  DateTime? _parseTime(String? raw) {
    if (raw == null) return null;
    final match = _timePattern.firstMatch(raw.trim());
    if (match == null) return null;
    int number(int group) => int.parse(match.group(group) ?? '0');

    final utc = DateTime.utc(
      number(1),
      number(2),
      number(3),
      number(4),
      number(5),
      number(6),
    );
    if (match.group(7) == null) return utc;
    final offset = Duration(hours: number(8), minutes: number(9));
    return match.group(7) == '+' ? utc.subtract(offset) : utc.add(offset);
  }
}
