import 'package:ip_tv/features/channels/domain/models/channel.dart';

class PlaylistValidationException implements Exception {
  const PlaylistValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlaylistValidator {
  static const _supportedSchemes = {'http', 'https', 'rtmp', 'rtsp'};

  void validate(List<Channel> channels) {
    if (channels.isEmpty) {
      throw const PlaylistValidationException(
        'Playlist does not contain any usable channels.',
      );
    }

    final ids = <String>{};
    for (final channel in channels) {
      if (channel.name.trim().isEmpty) {
        throw const PlaylistValidationException(
          'Channel names cannot be empty.',
        );
      }
      if (!ids.add(channel.id)) {
        throw const PlaylistValidationException('Channel IDs must be unique.');
      }

      final uri = Uri.tryParse(channel.streamUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          !_supportedSchemes.contains(uri.scheme.toLowerCase())) {
        throw PlaylistValidationException(
          'Channel "${channel.name}" has an unsupported stream URL.',
        );
      }
    }
  }
}