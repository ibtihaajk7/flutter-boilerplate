import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/notifications/local_notification_service.dart'; // slim:notifications
import 'package:flutter_boilerplate/features/home/counter_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart'; // slim:notifications
import 'package:provider/provider.dart';

import 'fakes.dart';

/// Screen sizes every screen must survive.
abstract final class TestScreens {
  static const Size smallPhone = Size(320, 568);
  static const Size phone = Size(390, 844);
  static const Size tablet = Size(1024, 1366);
}

/// What [PumpApp.pumpApp] wired in, for assertions.
class TestApp {
  const TestApp({
    required this.counter,
    required this.analytics, // slim:analytics
    required this.notifications, // slim:notifications
  });

  final CounterController counter;
  final FakeAnalyticsProvider analytics; // slim:analytics
  final MockLocalNotificationService notifications; // slim:notifications
}

extension PumpApp on WidgetTester {
  /// Pumps the real [App] on a screen of [size] with a system text scale of
  /// [textScale], so layout bugs show up the way they would on a device.
  /// Services are fakes; nothing touches the platform.
  Future<TestApp> pumpApp({
    Size size = TestScreens.phone,
    double textScale = 1.0,
    double devicePixelRatio = 3.0,
    Locale locale = const Locale('en'),
    bool notificationPermission = true, // slim:notifications
  }) async {
    view.physicalSize = size * devicePixelRatio;
    view.devicePixelRatio = devicePixelRatio;
    platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(view.reset);
    addTearDown(platformDispatcher.clearTextScaleFactorTestValue);

    // slim:analytics:start
    final analyticsProvider = FakeAnalyticsProvider();
    final analytics = AnalyticsService([analyticsProvider]);
    // slim:analytics:end
    final counter = CounterController(
      analytics, // slim:analytics
    );
    // slim:notifications:start
    final notifications = MockLocalNotificationService();
    when(
      notifications.requestPermission,
    ).thenAnswer((_) async => notificationPermission);
    when(
      () => notifications.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    // slim:notifications:end

    await pumpWidget(
      MultiProvider(
        providers: [
          Provider<AnalyticsService>.value(value: analytics), // slim:analytics
          // slim:notifications:start
          Provider<LocalNotificationService>.value(
            value: notifications,
          ),
          // slim:notifications:end
          ChangeNotifierProvider.value(value: counter),
        ],
        child: App(locale: locale),
      ),
    );
    await pumpAndSettle();
    return TestApp(
      counter: counter,
      analytics: analyticsProvider, // slim:analytics
      notifications: notifications, // slim:notifications
    );
  }
}
