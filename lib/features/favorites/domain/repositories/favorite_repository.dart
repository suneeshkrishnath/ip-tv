import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';

abstract interface class FavoriteRepository {
  Future<Result<List<Channel>>> getFavorites();

  Future<Result<void>> addFavorite(Channel channel);

  Future<Result<void>> removeFavorite(String channelId);
}