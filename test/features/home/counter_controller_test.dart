import 'package:flutter_boilerplate/features/home/counter_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CounterController controller;
  late int notifications;

  setUp(() {
    controller = CounterController();
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
