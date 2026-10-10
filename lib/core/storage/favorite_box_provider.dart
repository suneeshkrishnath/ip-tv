import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final favoriteBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>('favorites');
});