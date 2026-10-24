# Mixpanel

```bash
flutter pub add mixpanel_flutter
```

## Add the token

Add your project token to `.env` and `.env.example` (empty in the example):

```bash
MIXPANEL_TOKEN=your-project-token
```

And expose it in `lib/core/env/app_env.dart`:

```dart
static String get mixpanelToken => dotenv.maybeGet('MIXPANEL_TOKEN') ?? '';
```

## Add the provider

Save as `lib/core/analytics/mixpanel_analytics_provider.dart`:

```dart
import 'package:flutter_boilerplate/core/analytics/analytics_provider.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixpanelAnalyticsProvider implements AnalyticsProvider {
  MixpanelAnalyticsProvider({
    required this._token,
    Future<Mixpanel> Function(String token)? create,
  }) : _create = create ?? _defaultCreate;

  final String _token;
  final Future<Mixpanel> Function(String token) _create;
  Mixpanel? _mixpanel;

  static Future<Mixpanel> _defaultCreate(String token) =>
      Mixpanel.init(token, trackAutomaticEvents: true);

  @override
  Future<void> init() async => _mixpanel = await _create(_token);

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async =>
      _mixpanel?.track(name, properties: parameters);

  @override
  Future<void> logScreenView(String screenName) async =>
      _mixpanel?.track('screen_view', properties: {'screen_name': screenName});

  @override
  Future<void> setUserId(String? id) async {
    final mixpanel = _mixpanel;
    if (mixpanel == null) return;
    if (id == null) {
      await mixpanel.reset();
    } else {
      await mixpanel.identify(id);
    }
  }

  @override
  Future<void> setUserProperty(String name, String value) async =>
      _mixpanel?.getPeople().set(name, value);

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      _mixpanel?.optInTracking();
    } else {
      _mixpanel?.optOutTracking();
    }
  }
}
```

## Register it

In `lib/main.dart`. Providers stack, so it runs side by side with Firebase
Analytics if you use both:

```dart
final analytics = AnalyticsService([
  if (kDebugMode) DebugAnalyticsProvider(),
  if (!kDebugMode) MixpanelAnalyticsProvider(token: AppEnv.mixpanelToken),
]);
```

### Test it

Save as `test/core/analytics/mixpanel_analytics_provider_test.dart`. It runs with `make check` like every other test.

```dart
import 'package:flutter_boilerplate/core/analytics/mixpanel_analytics_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:mocktail/mocktail.dart';

class _MockMixpanel extends Mock implements Mixpanel {}

class _MockPeople extends Mock implements People {}

void main() {
  late _MockMixpanel mixpanel;
  late _MockPeople people;
  late MixpanelAnalyticsProvider provider;
  String? createdWith;

  setUp(() {
    mixpanel = _MockMixpanel();
    people = _MockPeople();
    provider = MixpanelAnalyticsProvider(
      token: 'token-123',
      create: (token) async {
        createdWith = token;
        return mixpanel;
      },
    );
    when(
      () => mixpanel.track(any(), properties: any(named: 'properties')),
    ).thenAnswer((_) async {});
    when(() => mixpanel.identify(any())).thenAnswer((_) async {});
    when(mixpanel.reset).thenAnswer((_) async {});
    when(mixpanel.getPeople).thenReturn(people);
  });

  test('does nothing before init', () async {
    await provider.logEvent('sign_up');
    await provider.setUserId('u1');

    verifyZeroInteractions(mixpanel);
  });

  test('maps every call onto Mixpanel', () async {
    await provider.init();
    await provider.logEvent('sign_up', parameters: {'method': 'email'});
    await provider.logScreenView('home');
    await provider.setUserId('u1');
    await provider.setUserId(null);
    await provider.setUserProperty('plan', 'pro');
    await provider.setEnabled(false);
    await provider.setEnabled(true);

    expect(createdWith, 'token-123');
    verify(
      () => mixpanel.track('sign_up', properties: {'method': 'email'}),
    ).called(1);
    verify(
      () => mixpanel.track('screen_view', properties: {'screen_name': 'home'}),
    ).called(1);
    verify(() => mixpanel.identify('u1')).called(1);
    verify(mixpanel.reset).called(1);
    verify(() => people.set('plan', 'pro')).called(1);
    verify(mixpanel.optOutTracking).called(1);
    verify(mixpanel.optInTracking).called(1);
  });
}
```
