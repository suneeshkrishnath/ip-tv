import 'package:dio/dio.dart';
import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/logging/app_logger.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/playlists/data/datasources/playlist_local_data_source.dart';
import 'package:ip_tv/features/playlists/data/datasources/playlist_remote_data_source.dart';
import 'package:ip_tv/features/playlists/data/parsers/m3u_parser.dart';
import 'package:ip_tv/features/playlists/data/validators/playlist_validator.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist.dart';
import 'package:ip_tv/features/playlists/domain/models/playlist_source.dart';
import 'package:ip_tv/features/playlists/domain/repositories/playlist_repository.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  PlaylistRepositoryImpl({
    required PlaylistRemoteDataSource remoteDataSource,
    required PlaylistLocalDataSource localDataSource,
    required M3uParser parser,
    required PlaylistValidator validator,
    DateTime Function()? clock,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _parser = parser,
       _validator = validator,
       _clock = clock ?? DateTime.now;

  final PlaylistRemoteDataSource _remoteDataSource;
  final PlaylistLocalDataSource _localDataSource;
  final M3uParser _parser;
  final PlaylistValidator _validator;
  final DateTime Function() _clock;

  @override
  Future<Result<Playlist>> loadPlaylist(PlaylistSource source) async {
    late final List<Channel> channels;
    try {
      final content = await _remoteDataSource.fetch(source.url);
      channels = _parser.parse(content);
      _validator.validate(channels);
    } on DioException catch (error, stackTrace) {
      appLogger.e('Playlist download failed', error: error, stackTrace: stackTrace);
      return FailureResult(
        NetworkFailure('Unable to download ${source.name}.', cause: error),
      );
    } on M3uParseException catch (error, stackTrace) {
      appLogger.e('Playlist parsing failed', error: error, stackTrace: stackTrace);
      return FailureResult(
        PlaylistParsingFailure(error.message, cause: error),
      );
    } on PlaylistValidationException catch (error, stackTrace) {
      appLogger.e('Playlist validation failed', error: error, stackTrace: stackTrace);
      return FailureResult(
        PlaylistValidationFailure(error.message, cause: error),
      );
    } catch (error, stackTrace) {
      appLogger.e('Unexpected playlist failure', error: error, stackTrace: stackTrace);
      return FailureResult(
        UnknownFailure('Unable to load ${source.name}.', cause: error),
      );
    }

    final playlist = Playlist(
      id: source.id,
      name: source.name,
      sourceUrl: source.url,
      channels: channels,
      lastUpdated: _clock().toUtc(),
    );
    try {
      await _localDataSource.cache(playlist);
    } catch (error, stackTrace) {
      appLogger.e('Playlist cache write failed', error: error, stackTrace: stackTrace);
      return FailureResult(
        CacheFailure('Unable to cache ${source.name}.', cause: error),
      );
    }
    return Success(playlist);
  }

  @override
  Future<Result<Playlist?>> getCachedPlaylist(String playlistId) async {
    try {
      return Success(await _localDataSource.get(playlistId));
    } catch (error, stackTrace) {
      appLogger.e('Playlist cache read failed', error: error, stackTrace: stackTrace);
      return FailureResult(
        CacheFailure('Unable to read the cached playlist.', cause: error),
      );
    }
  }
}