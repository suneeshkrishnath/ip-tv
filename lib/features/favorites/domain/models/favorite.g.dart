// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Favorite _$FavoriteFromJson(Map<String, dynamic> json) => _Favorite(
  channelId: json['channelId'] as String,
  addedAt: DateTime.parse(json['addedAt'] as String),
);

Map<String, dynamic> _$FavoriteToJson(_Favorite instance) => <String, dynamic>{
  'channelId': instance.channelId,
  'addedAt': instance.addedAt.toIso8601String(),
};
