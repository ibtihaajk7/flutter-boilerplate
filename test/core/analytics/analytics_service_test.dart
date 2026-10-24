import 'package:flutter_boilerplate/core/analytics/analytics_provider.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

class _ThrowingProvider extends FakeAnalyticsProvider {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) =>
      Future.error(StateError('vendor down'));
}

void main() {
  late FakeAnalyticsProvider first;
  late FakeAnalyticsProvider second;
  late AnalyticsService analytics;

  setUp(() {
    first = FakeAnalyticsProvider();
    second = FakeAnalyticsProvider();
    analytics = AnalyticsService([first, second]);
  });

  test('fans every call out to all providers', () async {
    await analytics.init();
    await analytics.track('sign_up', {'method': 'email'});
    await analytics.logScreenView('home');
    await analytics.setUserId('u1');
    await analytics.setUserProperty('plan', 'pro');

    const expected = [
      'init',
      'event:sign_up',
      'screen:home',
      'user:u1',
      'property:plan=pro',
    ];
    expect(first.calls, expected);
    expect(second.calls, expected);
    expect(first.events.single.$2, {'method': 'email'});
  });

  test('a failing provider does not stop the others', () async {
    final working = FakeAnalyticsProvider();
    final service = AnalyticsService(<AnalyticsProvider>[
      _ThrowingProvider(),
      working,
    ]);

    await service.track('sign_up');

    expect(working.calls, ['event:sign_up']);
  });

  test('when disabled, sends nothing but still tells providers', () async {
    await analytics.setEnabled(false);
    await analytics.track('sign_up');
    await analytics.logScreenView('home');
    await analytics.setUserId('u1');
    await analytics.setUserProperty('plan', 'pro');

    expect(analytics.isEnabled, isFalse);
    expect(first.calls, ['enabled:false']);
  });

  test('can start disabled', () async {
    final service = AnalyticsService([first], enabled: false);

    await service.track('sign_up');

    expect(first.calls, isEmpty);
  });

  test('asserts on names vendors would reject', () {
    expect(() => analytics.track('Sign Up'), throwsAssertionError);
    expect(
      () => analytics.track('sign_up', {'Bad Param': 1}),
      throwsAssertionError,
    );
    expect(
      () => analytics.setUserProperty('Plan', 'pro'),
      throwsAssertionError,
    );
  });
}
