import 'package:ip_tv/features/epg/domain/models/program.dart';

/// Programmes grouped by normalized XMLTV channel id, each list sorted by start.
class EpgGuide {
  EpgGuide(Map<String, List<Program>> programsByChannel, {this.fetchedAt})
    : _programs = {
        for (final entry in programsByChannel.entries)
          entry.key: ([...entry.value]
            ..sort((a, b) => a.start.compareTo(b.start))),
      };

  factory EpgGuide.fromJson(Map<String, dynamic> json) => EpgGuide(
    {
      for (final entry in (json['programs'] as Map<String, dynamic>).entries)
        entry.key: [
          for (final item in entry.value as List)
            Program.fromJson(item as Map<String, dynamic>),
        ],
    },
    fetchedAt: DateTime.tryParse(json['fetchedAt'] as String? ?? ''),
  );

  final Map<String, List<Program>> _programs;
  final DateTime? fetchedAt;

  /// Drops the `@quality` suffix used by iptv-org ids and ignores case.
  static String normalizeId(String id) {
    final at = id.indexOf('@');
    return (at == -1 ? id : id.substring(0, at)).trim().toLowerCase();
  }

  bool get isEmpty => _programs.values.every((list) => list.isEmpty);

  List<Program> _forChannel(String? epgId) {
    if (epgId == null) return const [];
    return _programs[normalizeId(epgId)] ?? const [];
  }

  Program? currentProgram(String? epgId, DateTime now) {
    for (final program in _forChannel(epgId)) {
      if (!program.start.isAfter(now) && program.end.isAfter(now)) {
        return program;
      }
    }
    return null;
  }

  Program? nextProgram(String? epgId, DateTime now) {
    for (final program in _forChannel(epgId)) {
      if (program.start.isAfter(now)) return program;
    }
    return null;
  }

  /// Programmes that have not finished yet, in start order.
  List<Program> scheduleFor(String? epgId, DateTime now) => [
    for (final program in _forChannel(epgId))
      if (program.end.isAfter(now)) program,
  ];

  Map<String, dynamic> toJson() => {
    'fetchedAt': fetchedAt?.toUtc().toIso8601String(),
    'programs': {
      for (final entry in _programs.entries)
        entry.key: [for (final p in entry.value) p.toJson()],
    },
  };
}
