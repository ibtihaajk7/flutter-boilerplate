import 'package:flutter_boilerplate/core/analytics/analytics_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts snake_case names up to 40 characters', () {
    expect(isValidAnalyticsName('button_tap'), isTrue);
    expect(isValidAnalyticsName('a' * 40), isTrue);
  });

  test('rejects names vendors would drop', () {
    expect(isValidAnalyticsName(''), isFalse);
    expect(isValidAnalyticsName('ButtonTap'), isFalse);
    expect(isValidAnalyticsName('button-tap'), isFalse);
    expect(isValidAnalyticsName('1st_tap'), isFalse);
    expect(isValidAnalyticsName('a' * 41), isFalse);
  });

  test('every declared event and parameter name is valid', () {
    const names = [
      AnalyticsEvents.buttonTap,
      AnalyticsEvents.counterIncremented,
      AnalyticsParams.buttonName,
      AnalyticsParams.count,
    ];
    expect(names.where((name) => !isValidAnalyticsName(name)), isEmpty);
  });
}
