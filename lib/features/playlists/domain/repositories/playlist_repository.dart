import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';

abstract interface class PlaylistRepository {
  Future<Result<Playlist>> loadPlaylist(PlaylistSource source);

  Future<Result<Playlist?>> getCachedPlaylist(String playlistId);
}