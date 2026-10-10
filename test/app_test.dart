import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/app/app.dart';
import 'package:ip_tv/features/favorites/application/favorite_providers.dart';

import 'support/fake_favorite_repository.dart';

void main() {
  testWidgets('app routes to the IPTV home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteRepositoryProvider.overrideWithValue(FakeFavoriteRepository()),
        ],
        child: const IptvApp(),
      ),
    );
      await tester.pumpAndSettle();

    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('No playlist loaded'), findsOneWidget);
  });
}