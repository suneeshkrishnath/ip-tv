import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';
import 'package:ip_tv/features/favorites/domain/repositories/favorite_repository.dart';

class FakeFavoriteRepository implements FavoriteRepository {
  final List<Channel> channels = [];

  @override
  Future<Result<List<Channel>>> getFavorites() async =>
      Success(List.unmodifiable(channels));

  @override
  Future<Result<void>> addFavorite(Channel channel) async {
    if (!channels.any((favorite) => favorite.id == channel.id)) {
      channels.add(channel);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> removeFavorite(String channelId) async {
    channels.removeWhere((channel) => channel.id == channelId);
    return const Success(null);
  }
}