import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('tapping + updates the counter and enables reset', (
    tester,
  ) async {
    final app = await tester.pumpApp();

    expect(find.text('No taps yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('Tapped once'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(app.counter.count, 0);
  });

  testWidgets('shows French copy for a French locale', (tester) async {
    await tester.pumpApp(locale: const Locale('fr'));

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Aucun appui pour l\'instant'), findsOneWidget);
  });

  group('no overflow', () {
    final cases = <String, ({Size size, double textScale})>{
      'small phone, large text': (size: TestScreens.smallPhone, textScale: 2),
      'phone, default text': (size: TestScreens.phone, textScale: 1),
      'tablet, large text': (size: TestScreens.tablet, textScale: 2),
    };

    for (final MapEntry(key: name, value: screen) in cases.entries) {
      testWidgets(name, (tester) async {
        await tester.pumpApp(size: screen.size, textScale: screen.textScale);

        // A RenderFlex overflow is reported as an exception during layout.
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('tablet lays the cards out side by side', (tester) async {
    await tester.pumpApp(size: TestScreens.tablet);

    final intro = tester.getTopLeft(find.text('Welcome'));
    final counter = tester.getTopLeft(find.text('No taps yet'));
    expect(counter.dx, greaterThan(intro.dx));
  });
}
