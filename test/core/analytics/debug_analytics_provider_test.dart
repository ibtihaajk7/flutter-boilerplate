import 'package:flutter_boilerplate/core/analytics/debug_analytics_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logs every call', () async {
    final lines = <String>[];
    final provider = DebugAnalyticsProvider(log: lines.add);

    await provider.init();
    await provider.logEvent('sign_up', parameters: {'method': 'email'});
    await provider.logEvent('app_open');
    await provider.logScreenView('home');
    await provider.setUserId('u1');
    await provider.setUserProperty('plan', 'pro');
    await provider.setEnabled(false);

    expect(lines, [
      '[analytics] init',
      '[analytics] sign_up {method: email}',
      '[analytics] app_open {}',
      '[analytics] screen home',
      '[analytics] user u1',
      '[analytics] property plan=pro',
      '[analytics] enabled false',
    ]);
  });

  test('defaults to debugPrint', () async {
    await expectLater(DebugAnalyticsProvider().init(), completes);
  });
}
