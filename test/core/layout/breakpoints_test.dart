import 'package:flutter_boilerplate/core/layout/breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widths below the tablet breakpoint are phones', () {
    expect(ScreenType.fromWidth(320), ScreenType.phone);
    expect(ScreenType.fromWidth(599.9), ScreenType.phone);
  });

  test('widths from the tablet breakpoint are tablets', () {
    expect(ScreenType.fromWidth(600), ScreenType.tablet);
    expect(ScreenType.fromWidth(1024), ScreenType.tablet);
  });
}
