import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';

abstract interface class UserPlaylistsRepository {
  Future<Result<List<PlaylistSource>>> getAll();

  Future<Result<PlaylistSource>> add({required String name, required String url});

  Future<Result<PlaylistSource>> edit({
    required String id,
    required String name,
    required String url,
  });

  /// Also removes the playlist's cached channels.
  Future<Result<void>> delete(String id);
}
