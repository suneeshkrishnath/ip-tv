import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';

abstract interface class PlaylistLocalDataSource {
  Future<void> cache(Playlist playlist);

  Future<Playlist?> get(String playlistId);

  Future<void> remove(String playlistId);
}

class HivePlaylistLocalDataSource implements PlaylistLocalDataSource {
  const HivePlaylistLocalDataSource(this._box);

  final Box<String> _box;

  @override
  Future<void> cache(Playlist playlist) async {
    await _box.put(playlist.id, jsonEncode(playlist.toJson()));
  }

  @override
  Future<Playlist?> get(String playlistId) async {
    final encoded = _box.get(playlistId);
    if (encoded == null) return null;

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Cached playlist must be a JSON object.');
    }
    return Playlist.fromJson(decoded);
  }

  @override
  Future<void> remove(String playlistId) => _box.delete(playlistId);
}