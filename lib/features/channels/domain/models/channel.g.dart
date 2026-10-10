// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Channel _$ChannelFromJson(Map<String, dynamic> json) => _Channel(
  id: json['id'] as String,
  name: json['name'] as String,
  streamUrl: json['streamUrl'] as String,
  category: json['category'] as String? ?? '',
  logoUrl: json['logoUrl'] as String?,
  epgId: json['epgId'] as String?,
);

Map<String, dynamic> _$ChannelToJson(_Channel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'streamUrl': instance.streamUrl,
  'category': instance.category,
  'logoUrl': instance.logoUrl,
  'epgId': instance.epgId,
};
