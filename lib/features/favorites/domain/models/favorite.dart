import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite.freezed.dart';
part 'favorite.g.dart';

/// Records when a channel was added to favorites.
@freezed
abstract class Favorite with _$Favorite {
  const factory Favorite({
    required String channelId,
    required DateTime addedAt,
  }) = _Favorite;

  factory Favorite.fromJson(Map<String, dynamic> json) =>
      _$FavoriteFromJson(json);
}