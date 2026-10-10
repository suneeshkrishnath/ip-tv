import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/domain/models/favorite.dart';

abstract interface class FavoriteLocalDataSource {
  Future<List<Channel>> getAll();

  Future<void> add(Channel channel);

  Future<void> remove(String channelId);
}

class HiveFavoriteLocalDataSource implements FavoriteLocalDataSource {
  const HiveFavoriteLocalDataSource(this._box);

  final Box<String> _box;

  @override
  Future<List<Channel>> getAll() async {
    return _box.values.map((encoded) {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic> ||
          decoded['channel'] is! Map<String, dynamic>) {
        throw const FormatException('Cached favorite is invalid.');
      }
      return Channel.fromJson(decoded['channel'] as Map<String, dynamic>);
    }).toList(growable: false);
  }

  @override
  Future<void> add(Channel channel) async {
    final favorite = Favorite(
      channelId: channel.id,
      addedAt: DateTime.now().toUtc(),
    );
    await _box.put(
      channel.id,
      jsonEncode({'favorite': favorite.toJson(), 'channel': channel.toJson()}),
    );
  }

  @override
  Future<void> remove(String channelId) => _box.delete(channelId);
}