import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ip_tv/core/storage/hive_providers.dart';

const _acceptedKey = 'disclaimer_accepted';

final disclaimerAcceptedProvider =
    NotifierProvider<DisclaimerNotifier, bool>(DisclaimerNotifier.new);

class DisclaimerNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsBoxProvider).get(_acceptedKey) == 'true';

  Future<void> accept() async {
    await ref.read(settingsBoxProvider).put(_acceptedKey, 'true');
    state = true;
  }
}
