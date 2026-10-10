import 'package:ip_tv/features/channels/domain/models/channel.dart';

class M3uParseException extends FormatException {
  M3uParseException(super.message);
}

class M3uParser {
  static final _attributePattern = RegExp(r'([\w-]+)\s*=\s*"([^"]*)"');

  List<Channel> parse(String content) {
    final normalizedContent = content.replaceFirst('\uFEFF', '');
    final lines = normalizedContent.split(RegExp(r'\r?\n'));
    final firstLine = lines.map((line) => line.trim()).firstWhere(
          (line) => line.isNotEmpty,
          orElse: () => '',
        );
    if (firstLine.toUpperCase() != '#EXTM3U') {
      throw M3uParseException('Playlist must start with #EXTM3U.');
    }

    final channels = <Channel>[];
    final usedIds = <String, int>{};
    _ChannelMetadata? pending;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.toUpperCase() == '#EXTM3U') continue;

      if (line.toUpperCase().startsWith('#EXTINF:')) {
        pending = _parseMetadata(line);
        continue;
      }
      if (line.startsWith('#') || pending == null) continue;

      final baseId = _createBaseId(pending.epgId, pending.name);
      final duplicateCount = usedIds.update(
        baseId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      final id = duplicateCount == 1 ? baseId : '$baseId-$duplicateCount';
      channels.add(
        Channel(
          id: id,
          name: pending.name,
          streamUrl: line,
          category: pending.category,
          logoUrl: pending.logoUrl,
          epgId: pending.epgId,
        ),
      );
      pending = null;
    }

    if (channels.isEmpty) {
      throw M3uParseException('Playlist does not contain any channels.');
    }
    return List.unmodifiable(channels);
  }

  _ChannelMetadata _parseMetadata(String line) {
    final commaIndex = line.indexOf(',');
    if (commaIndex < 0 || commaIndex == line.length - 1) {
      throw M3uParseException('Channel entry is missing its display name.');
    }

    final attributes = <String, String>{};
    for (final match in _attributePattern.allMatches(line.substring(0, commaIndex))) {
      attributes[match.group(1)!.toLowerCase()] = match.group(2)!.trim();
    }

    final name = line.substring(commaIndex + 1).trim();
    if (name.isEmpty) {
      throw M3uParseException('Channel display name cannot be empty.');
    }
    return _ChannelMetadata(
      name: name,
      epgId: _nonEmpty(attributes['tvg-id']),
      logoUrl: _nonEmpty(attributes['tvg-logo']),
      category: attributes['group-title'] ?? '',
    );
  }

  String _createBaseId(String? epgId, String name) {
    if (epgId != null) return epgId;
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'channel' : slug;
  }

  String? _nonEmpty(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }
}

class _ChannelMetadata {
  const _ChannelMetadata({
    required this.name,
    required this.category,
    this.epgId,
    this.logoUrl,
  });

  final String name;
  final String category;
  final String? epgId;
  final String? logoUrl;
}