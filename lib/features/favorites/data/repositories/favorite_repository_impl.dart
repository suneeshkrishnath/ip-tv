import 'package:ip_tv/core/errors/app_failure.dart';
import 'package:ip_tv/core/logging/app_logger.dart';
import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/data/datasources/favorite_local_data_source.dart';
import 'package:ip_tv/features/favorites/domain/repositories/favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  const FavoriteRepositoryImpl(this._localDataSource);

  final FavoriteLocalDataSource _localDataSource;

  @override
  Future<Result<List<Channel>>> getFavorites() async {
    try {
      return Success(await _localDataSource.getAll());
    } catch (error, stackTrace) {
      appLogger.e('Favorite read failed', error: error, stackTrace: stackTrace);
      return FailureResult(
        CacheFailure('Unable to load favorites.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> addFavorite(Channel channel) async {
    try {
      await _localDataSource.add(channel);
      return const Success(null);
    } catch (error, stackTrace) {
      appLogger.e('Favorite write failed', error: error, stackTrace: stackTrace);
      return FailureResult(
        CacheFailure('Unable to save this favorite.', cause: error),
      );
    }
  }

  @override
  Future<Result<void>> removeFavorite(String channelId) async {
    try {
      await _localDataSource.remove(channelId);
      return const Success(null);
    } catch (error, stackTrace) {
      appLogger.e('Favorite removal failed', error: error, stackTrace: stackTrace);
      return FailureResult(
        CacheFailure('Unable to remove this favorite.', cause: error),
      );
    }
  }
}