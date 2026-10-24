import 'package:flutter_boilerplate/core/analytics/analytics_events.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart'; // slim:analytics
import 'package:flutter_boilerplate/features/home/counter_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAnalyticsProvider analytics; // slim:analytics
  late CounterController controller;
  late int notifications;

  setUp(() {
    analytics = FakeAnalyticsProvider(); // slim:analytics
    controller = CounterController(
      AnalyticsService([analytics]), // slim:analytics
    );
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('starts at zero', () {
    expect(controller.count, 0);
  });

  test('increment adds one and notifies', () {
    controller
      ..increment()
      ..increment();

    expect(controller.count, 2);
    expect(notifications, 2);
  });

  // slim:analytics:start
  test('increment tracks the new count', () async {
    controller.increment();
    await pumpEventQueue();

    final (name, parameters) = analytics.events.single;
    expect(name, AnalyticsEvents.counterIncremented);
    expect(parameters, {AnalyticsParams.count: 1});
  });
  // slim:analytics:end

  test('reset goes back to zero and notifies', () {
    controller
      ..increment()
      ..reset();

    expect(controller.count, 0);
    expect(notifications, 2);
  });

  test('reset at zero does not notify', () {
    controller.reset();

    expect(notifications, 0);
  });
}
