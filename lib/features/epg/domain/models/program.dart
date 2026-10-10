import 'package:freezed_annotation/freezed_annotation.dart';

part 'program.freezed.dart';
part 'program.g.dart';

/// An electronic programme guide entry for a channel and time range.
@freezed
abstract class Program with _$Program {
  const factory Program({
    required String id,
    required String channelId,
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
  }) = _Program;

  factory Program.fromJson(Map<String, dynamic> json) =>
      _$ProgramFromJson(json);
}