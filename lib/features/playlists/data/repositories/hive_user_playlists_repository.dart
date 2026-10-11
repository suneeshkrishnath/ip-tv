import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/playlists/data/datasources/playlist_local_data_source.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/user_playlists_repository.dart';

class HiveUserPlaylistsRepository implements UserPlaylistsRepository {
  HiveUserPlaylistsRepository(
    this._box,
    this._cache, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const _key = 'user_playlists';

  final Box<String> _box;
  final PlaylistLocalDataSource _cache;
  final DateTime Function() _clock;

  @override
  Future<Result<List<PlaylistSource>>> getAll() async {
    try {
      return Success(_read());
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to read saved playlists.', cause: error),
      );
    }
  }

  @override
  Future<Result<PlaylistSource>> add({
    required String name,
    required String url,
  }) async {
    final invalid = _validate(name, url);
    if (invalid != null) return FailureResult(invalid);
    try {
      final source = PlaylistSource(
        id: 'user-${_clock().microsecondsSinceEpoch}',
        name: name.trim(),
        url: url.trim(),
      );
      await _write([..._read(), source]);
      return Success(source);
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to save the playlist.', cause: error),
      );
    }
  }

  @override
  Future<Result<PlaylistSource>> edit({
    required String id,
    required String name,
    required String url,
  }) async {
    final invalid = _validate(name, url);
    if (invalid != null) return FailureResult(invalid);
    try {
      final sources = _read();
      final index = sources.indexWhere((source) => source.id == id);
      if (index == -1) {
        return const FailureResult(
          PlaylistValidationFailure('Playlist no longer exists.'),
        );
      }
      final updated = PlaylistSource(
        id: id,
        name: name.trim(),
        url: url.trim(),
      );
      if (sources[index].url != updated.url) await _cache.remove(id);
      sources[index] = updated;
      await _write(sources);
      return Success(updated);
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to save the playlist.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _write(_read().where((source) => source.id != id).toList());
      await _cache.remove(id);
      return const Success(null);
    } on Object catch (error) {
      return FailureResult(
        CacheFailure('Unable to delete the playlist.', cause: error),
      );
    }
  }

  AppFailure? _validate(String name, String url) {
    if (name.trim().isEmpty) {
      return const PlaylistValidationFailure('Enter a playlist name.');
    }
    final uri = Uri.tryParse(url.trim());
    final valid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid
        ? null
        : const PlaylistValidationFailure(
            'Enter a valid http or https playlist URL.',
          );
  }

  List<PlaylistSource> _read() {
    final encoded = _box.get(_key);
    if (encoded == null) return [];
    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('Saved playlists must be a JSON list.');
    }
    return decoded
        .map((item) => PlaylistSource.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _write(List<PlaylistSource> sources) =>
      _box.put(_key, jsonEncode(sources.map((s) => s.toJson()).toList()));
}
