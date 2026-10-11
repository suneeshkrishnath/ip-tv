import 'package:ip_tv/core/result/result.dart';
import 'package:ip_tv/features/epg/domain/models/epg_guide.dart';

abstract interface class EpgRepository {
  /// Downloads and parses the guide, keeping only [channelIds] when given.
  Future<Result<EpgGuide>> loadGuide(
    String epgUrl, {
    Set<String>? channelIds,
  });
}
