import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/domain/repositories/favorites_repository.dart';

class HiveFavoritesRepository implements FavoritesRepository {
  const HiveFavoritesRepository(this._box);

  final Box<String> _box;

  @override
  Future<Result<List<Channel>>> getFavorites() async {
    try {
      final entries = <({Channel channel, DateTime addedAt})>[];
      for (final encoded in _box.values) {
        final decoded = jsonDecode(encoded);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Favorite must be a JSON object.');
        }
        entries.add((
          channel: Channel.fromJson(decoded['channel'] as Map<String, dynamic>),
          addedAt: DateTime.parse(decoded['addedAt'] as String),
        ));
      }
      entries.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return Success(entries.map((e) => e.channel).toList(growable: false));
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to read favorites.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> addFavorite(Channel channel) async {
    try {
      await _box.put(
        channel.id,
        jsonEncode({
          'channel': channel.toJson(),
          'addedAt': DateTime.now().toIso8601String(),
        }),
      );
      return const Success(null);
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to save favorite.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> removeFavorite(String channelId) async {
    try {
      await _box.delete(channelId);
      return const Success(null);
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to remove favorite.', cause: error),
      );
    }
  }
}
