import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/app/app.dart';

void main() {
  testWidgets('app routes to the IPTV home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: IptvApp()));

    expect(find.text('IPTV'), findsOneWidget);
    expect(find.text('No playlist loaded'), findsOneWidget);
  });
}