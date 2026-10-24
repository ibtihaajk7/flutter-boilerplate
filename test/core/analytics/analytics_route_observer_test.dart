import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_route_observer.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAnalyticsProvider analytics;
  late GlobalKey<NavigatorState> navigator;

  Future<void> pumpNavigator(WidgetTester tester) async {
    analytics = FakeAnalyticsProvider();
    navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [
          AnalyticsRouteObserver(AnalyticsService([analytics])),
        ],
        home: const SizedBox.shrink(),
      ),
    );
  }

  Route<void> page(String? name) => MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox.shrink(),
  );

  testWidgets('logs named pages on push, replace and pop', (tester) async {
    await pumpNavigator(tester);

    navigator.currentState!.push(page('settings')).ignore();
    await tester.pumpAndSettle();
    navigator.currentState!.pushReplacement(page('profile')).ignore();
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(analytics.calls, [
      'screen:/',
      'screen:settings',
      'screen:profile',
      'screen:/',
    ]);
  });

  testWidgets('ignores unnamed pages and dialogs', (tester) async {
    await pumpNavigator(tester);

    navigator.currentState!.push(page(null)).ignore();
    await tester.pumpAndSettle();
    showDialog<void>(
      context: navigator.currentContext!,
      routeSettings: const RouteSettings(name: 'dialog'),
      builder: (_) => const SizedBox.shrink(),
    ).ignore();
    await tester.pumpAndSettle();

    expect(analytics.calls, ['screen:/']);
  });
}
