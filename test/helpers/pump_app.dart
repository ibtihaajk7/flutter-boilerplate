import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app.dart';
import 'package:flutter_boilerplate/features/home/counter_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

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
  });

  final CounterController counter;
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
  }) async {
    view.physicalSize = size * devicePixelRatio;
    view.devicePixelRatio = devicePixelRatio;
    platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(view.reset);
    addTearDown(platformDispatcher.clearTextScaleFactorTestValue);

    final counter = CounterController();

    await pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: counter),
        ],
        child: App(locale: locale),
      ),
    );
    await pumpAndSettle();
    return TestApp(
      counter: counter,
    );
  }
}
