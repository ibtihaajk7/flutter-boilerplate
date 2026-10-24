# Firebase Analytics

Requires [Firebase setup](firebase-setup.md).

```bash
flutter pub add firebase_analytics
```

## Add the provider

Save as `lib/core/analytics/firebase_analytics_provider.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_provider.dart';

class FirebaseAnalyticsProvider implements AnalyticsProvider {
  FirebaseAnalyticsProvider({FirebaseAnalytics? analytics})
    : _injected = analytics;

  final FirebaseAnalytics? _injected;

  // Resolved lazily: FirebaseAnalytics.instance needs Firebase.initializeApp.
  FirebaseAnalytics get _analytics => _injected ?? FirebaseAnalytics.instance;

  @override
  Future<void> init() async {}

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) =>
      _analytics.logEvent(name: name, parameters: parameters);

  @override
  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  @override
  Future<void> setUserId(String? id) => _analytics.setUserId(id: id);

  @override
  Future<void> setUserProperty(String name, String value) =>
      _analytics.setUserProperty(name: name, value: value);

  @override
  Future<void> setEnabled(bool enabled) =>
      _analytics.setAnalyticsCollectionEnabled(enabled);
}
```

## Register it

In `lib/main.dart`, send events to Firebase in profile and release builds and
keep printing them in debug, so test taps never reach your dashboard:

```dart
final analytics = AnalyticsService([
  if (kDebugMode) DebugAnalyticsProvider() else FirebaseAnalyticsProvider(),
]);
```

Screen views arrive automatically through `AnalyticsRouteObserver` for every
route with a name. To see events live while developing, use
[DebugView](https://firebase.google.com/docs/analytics/debugview).

### Test it

Save as `test/core/analytics/firebase_analytics_provider_test.dart`. It runs with `make check` like every other test.

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_boilerplate/core/analytics/firebase_analytics_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late _MockFirebaseAnalytics firebase;
  late FirebaseAnalyticsProvider provider;

  setUp(() {
    firebase = _MockFirebaseAnalytics();
    provider = FirebaseAnalyticsProvider(analytics: firebase);
    when(
      () => firebase.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => firebase.logScreenView(screenName: any(named: 'screenName')),
    ).thenAnswer((_) async {});
    when(
      () => firebase.setUserId(id: any(named: 'id')),
    ).thenAnswer((_) async {});
    when(
      () => firebase.setUserProperty(
        name: any(named: 'name'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => firebase.setAnalyticsCollectionEnabled(any()),
    ).thenAnswer((_) async {});
  });

  test('maps every call onto Firebase Analytics', () async {
    await provider.init();
    await provider.logEvent('sign_up', parameters: {'method': 'email'});
    await provider.logScreenView('home');
    await provider.setUserId('u1');
    await provider.setUserProperty('plan', 'pro');
    await provider.setEnabled(false);

    verify(
      () => firebase.logEvent(name: 'sign_up', parameters: {'method': 'email'}),
    ).called(1);
    verify(() => firebase.logScreenView(screenName: 'home')).called(1);
    verify(() => firebase.setUserId(id: 'u1')).called(1);
    verify(
      () => firebase.setUserProperty(name: 'plan', value: 'pro'),
    ).called(1);
    verify(() => firebase.setAnalyticsCollectionEnabled(false)).called(1);
  });
}
```
