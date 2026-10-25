import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_tv/features/disclaimer/application/disclaimer_providers.dart';
import 'package:ip_tv/features/disclaimer/presentation/disclaimer_gate.dart';

class FakeDisclaimer extends DisclaimerNotifier {
  FakeDisclaimer({required this.initial});

  final bool initial;
  bool saved = false;

  @override
  bool build() => initial;

  @override
  Future<void> accept() async {
    saved = true;
    state = true;
  }
}

void main() {
  testWidgets('requires the checkbox before the disclaimer can be closed',
      (tester) async {
    final notifier = FakeDisclaimer(initial: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [disclaimerAcceptedProvider.overrideWith(() => notifier)],
        child: const MaterialApp(
          home: DisclaimerGate(child: Scaffold(body: Text('Home'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(disclaimerTitle), findsOneWidget);
    expect(find.text(disclaimerMessage), findsOneWidget);
    expect(find.text(disclaimerCheckboxLabel), findsOneWidget);
    expect(find.text(disclaimerConfirmLabel), findsOneWidget);
    FilledButton button() =>
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button().onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(button().onPressed, isNotNull);

    await tester.tap(find.text(disclaimerConfirmLabel));
    await tester.pumpAndSettle();

    expect(find.text(disclaimerTitle), findsNothing);
    expect(notifier.saved, isTrue);
  });

  testWidgets('does not show again once accepted', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disclaimerAcceptedProvider.overrideWith(
            () => FakeDisclaimer(initial: true),
          ),
        ],
        child: const MaterialApp(
          home: DisclaimerGate(child: Scaffold(body: Text('Home'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(disclaimerTitle), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });
}
