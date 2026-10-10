import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

/// A named source and its most recently loaded channels.
@freezed
abstract class Playlist with _$Playlist {
  @JsonSerializable(explicitToJson: true)
  const factory Playlist({
    required String id,
    required String name,
    required String sourceUrl,
    @Default(<Channel>[]) List<Channel> channels,
    DateTime? lastUpdated,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) =>
      _$PlaylistFromJson(json);
}