import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/network/dio_provider.dart';
import 'package:ip_tv/core/storage/hive_providers.dart';
import 'package:ip_tv/features/playlists/data/datasources/playlist_local_data_source.dart';
import 'package:ip_tv/features/playlists/data/datasources/playlist_remote_data_source.dart';
import 'package:ip_tv/features/playlists/data/parsers/m3u_parser.dart';
import 'package:ip_tv/features/playlists/data/repositories/hive_user_playlists_repository.dart';
import 'package:ip_tv/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:ip_tv/features/playlists/data/validators/playlist_validator.dart';
import 'package:ip_tv/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:ip_tv/features/playlists/domain/repositories/user_playlists_repository.dart';

final userPlaylistsRepositoryProvider = Provider<UserPlaylistsRepository>(
  (ref) => HiveUserPlaylistsRepository(
    ref.watch(settingsBoxProvider),
    ref.watch(playlistLocalDataSourceProvider),
  ),
);

final playlistRemoteDataSourceProvider = Provider<PlaylistRemoteDataSource>(
  (ref) => DioPlaylistRemoteDataSource(ref.watch(dioProvider)),
);

final playlistLocalDataSourceProvider = Provider<PlaylistLocalDataSource>(
  (ref) => HivePlaylistLocalDataSource(ref.watch(playlistBoxProvider)),
);

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl(
    remoteDataSource: ref.watch(playlistRemoteDataSourceProvider),
    localDataSource: ref.watch(playlistLocalDataSourceProvider),
    parser: M3uParser(),
    validator: PlaylistValidator(),
  );
});