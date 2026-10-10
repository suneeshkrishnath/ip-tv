import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/features/player/presentation/player_session.dart';

final playerSessionFactoryProvider = Provider<PlayerSessionFactory>(
  (ref) => const MediaKitPlayerSessionFactory(),
);