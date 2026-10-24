import 'package:flutter_boilerplate/core/analytics/analytics_provider.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/notifications/local_notification_service.dart'; // slim:notifications
import 'package:mocktail/mocktail.dart'; // slim:notifications

// slim:analytics:start
/// Records every analytics call so tests can assert on them.
class FakeAnalyticsProvider implements AnalyticsProvider {
  final List<String> calls = [];
  final List<(String, Map<String, Object>?)> events = [];

  @override
  Future<void> init() async => calls.add('init');

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    calls.add('event:$name');
    events.add((name, parameters));
  }

  @override
  Future<void> logScreenView(String screenName) async =>
      calls.add('screen:$screenName');

  @override
  Future<void> setUserId(String? id) async => calls.add('user:$id');

  @override
  Future<void> setUserProperty(String name, String value) async =>
      calls.add('property:$name=$value');

  @override
  Future<void> setEnabled(bool enabled) async => calls.add('enabled:$enabled');
}
// slim:analytics:end

// slim:notifications:start
class MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

// slim:notifications:end
