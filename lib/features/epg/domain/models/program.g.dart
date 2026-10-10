// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Program _$ProgramFromJson(Map<String, dynamic> json) => _Program(
  id: json['id'] as String,
  channelId: json['channelId'] as String,
  title: json['title'] as String,
  start: DateTime.parse(json['start'] as String),
  end: DateTime.parse(json['end'] as String),
  description: json['description'] as String?,
);

Map<String, dynamic> _$ProgramToJson(_Program instance) => <String, dynamic>{
  'id': instance.id,
  'channelId': instance.channelId,
  'title': instance.title,
  'start': instance.start.toIso8601String(),
  'end': instance.end.toIso8601String(),
  'description': instance.description,
};
