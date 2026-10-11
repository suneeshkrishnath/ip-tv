import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const playlistsBoxName = 'playlists';
const favoritesBoxName = 'favorites';

final playlistBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(playlistsBoxName);
});

final favoritesBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(favoritesBoxName);
});