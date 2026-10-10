import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel.freezed.dart';
part 'channel.g.dart';

/// A playable channel described by an IPTV playlist.
@freezed
abstract class Channel with _$Channel {
  const factory Channel({
    required String id,
    required String name,
    required String streamUrl,
    @Default('') String category,
    String? logoUrl,
    String? epgId,
  }) = _Channel;

  factory Channel.fromJson(Map<String, dynamic> json) =>
      _$ChannelFromJson(json);
}