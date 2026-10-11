import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:ip_tv/features/epg/domain/models/epg_guide.dart';

abstract interface class EpgLocalDataSource {
  Future<EpgGuide?> get(String key);

  Future<void> put(String key, EpgGuide guide);
}

class HiveEpgLocalDataSource implements EpgLocalDataSource {
  const HiveEpgLocalDataSource(this._box);

  final Box<String> _box;

  @override
  Future<EpgGuide?> get(String key) async {
    final encoded = _box.get(key);
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Cached guide must be a JSON object.');
    }
    return EpgGuide.fromJson(decoded);
  }

  @override
  Future<void> put(String key, EpgGuide guide) =>
      _box.put(key, jsonEncode(guide.toJson()));
}
