import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/app/app.dart';
import 'package:ip_tv/features/disclaimer/application/disclaimer_providers.dart';

import 'disclaimer_test.dart' show FakeDisclaimer;

void main() {
  testWidgets('app routes to the IPTV home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disclaimerAcceptedProvider.overrideWith(
            () => FakeDisclaimer(initial: true),
          ),
        ],
        child: const IptvApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('No playlist loaded'), findsOneWidget);
  });
}