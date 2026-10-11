import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/channels/domain/models/channel.dart';

abstract interface class HistoryRepository {
  /// Returns watched channels, most recent first.
  Future<Result<List<Channel>>> getRecent();

  /// Moves [channel] to the front, dropping the oldest entries over the limit.
  Future<Result<void>> record(Channel channel);
}
