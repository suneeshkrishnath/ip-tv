import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const playlistsBoxName = 'playlists';
const favoritesBoxName = 'favorites';
const historyBoxName = 'history';
const settingsBoxName = 'settings';
const epgBoxName = 'epg';

final playlistBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(playlistsBoxName);
});

final favoritesBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(favoritesBoxName);
});

final historyBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(historyBoxName);
});

final settingsBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(settingsBoxName);
});

final epgBoxProvider = Provider<Box<String>>((ref) {
  return Hive.box<String>(epgBoxName);
});