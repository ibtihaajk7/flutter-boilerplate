# Push notifications (FCM)

Requires [Firebase setup](firebase-setup.md). Builds on the template's
`LocalNotificationService`, which shows foreground pushes on Android.

```bash
flutter pub add firebase_messaging
```

## Platform setup

**iOS** (push doesn't work on the simulator for most setups, so test on a
device):

1. In Xcode, open `ios/Runner.xcworkspace` → Runner target → **Signing &
   Capabilities**. Add **Push Notifications**, and **Background Modes** with
   **Remote notifications** checked.
2. In the [Apple Developer portal](https://developer.apple.com/account/resources/authkeys/list),
   create an APNs key (.p8).
3. Upload it in the Firebase console → Project settings → **Cloud
   Messaging** → Apple app configuration.

**Android**: nothing more. `POST_NOTIFICATIONS` is already in the manifest. To
have pushes use the template's notification channel, add inside
`<application>` in `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="general" />
```

## Add the service

Save as `lib/core/notifications/push_notification_service.dart`:

```dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/notifications/local_notification_service.dart';
import 'package:flutter_boilerplate/firebase_options.dart';

/// Handles pushes while the app is in the background or terminated. Runs in
/// its own isolate, so it must be a top-level function that initializes
/// Firebase itself. Register it in `main()` before `runApp`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Push notifications through Firebase Cloud Messaging.
///
/// - [onToken] gets the device token on startup and whenever it rotates:
///   send it to your backend so it can target this device.
/// - [onOpened] gets the message the user tapped, whether it opened the app
///   from terminated, from the background, or arrived in the foreground.
class PushNotificationService {
  PushNotificationService({
    required this._localNotifications,
    required this._onToken,
    this._onOpened,
    this._onMessage,
    this._onMessageOpenedApp,
    FirebaseMessaging? messaging,
  }) : _injected = messaging;

  final LocalNotificationService _localNotifications;
  final Future<void> Function(String token) _onToken;
  final void Function(RemoteMessage message)? _onOpened;
  final FirebaseMessaging? _injected;
  final Stream<RemoteMessage>? _onMessage;
  final Stream<RemoteMessage>? _onMessageOpenedApp;
  final List<StreamSubscription<Object>> _subscriptions = [];

  FirebaseMessaging get _messaging => _injected ?? FirebaseMessaging.instance;

  /// Starts listening. Doesn't ask for permission: call
  /// [requestPermission] when the user opts in.
  Future<void> init() async {
    // iOS: show pushes as banners while the app is open.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _subscriptions
      ..add(
        (_onMessage ?? FirebaseMessaging.onMessage).listen(_showInForeground),
      )
      ..add(
        (_onMessageOpenedApp ?? FirebaseMessaging.onMessageOpenedApp).listen(
          (message) => _onOpened?.call(message),
        ),
      )
      ..add(_messaging.onTokenRefresh.listen(_onToken));

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onOpened?.call(initial);

    if (await _isAuthorized()) await _sendToken();
  }

  /// Asks for permission (iOS, and Android 13+) and registers the device.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    final granted = _granted(settings.authorizationStatus);
    if (granted) await _sendToken();
    return granted;
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  Future<bool> _isAuthorized() async => _granted(
    (await _messaging.getNotificationSettings()).authorizationStatus,
  );

  static bool _granted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> _sendToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _onToken(token);
  }

  /// Android doesn't display pushes while the app is in the foreground, so
  /// show them as local notifications. iOS uses the presentation options.
  void _showInForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _localNotifications
        .show(
          id: message.messageId.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: message.data['route']?.toString(),
        )
        .ignore();
  }
}
```

## Register it

In `lib/main.dart`, right after `Firebase.initializeApp`:

```dart
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```

After `notifications` is created:

```dart
final push = PushNotificationService(
  localNotifications: notifications,
  onToken: (token) async {
    // Send the token to your backend, keyed by the signed-in user.
  },
  onOpened: (message) {
    // Navigate using message.data, e.g. message.data['route'].
  },
);
```

Then provide it with `Provider<PushNotificationService>.value(value: push)` and
add `'push': push.init` to the steps in `_deferredInit`.

Ask for permission when the user opts in (never on launch):

```dart
final granted = await context.read<PushNotificationService>().requestPermission();
```

## Storing tokens

A device token identifies an install, not a user. A pattern that holds up:

- Store tokens under the user, e.g. `users/{uid}/tokens/{token}` with an
  `updatedAt` timestamp, so one user can have several devices.
- Save it from `onToken`, which fires on startup and on every refresh.
- Delete it on sign-out, and drop tokens your backend gets
  `messaging/registration-token-not-registered` for.

## Send a test push

Print the token in debug, then Firebase console → **Messaging** → **New
campaign** → **Send test message**, and paste it.

### Test it

Save as `test/core/notifications/push_notification_service_test.dart`. It runs with `make check` like every other test.

```dart
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/notifications/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

NotificationSettings _settings(AuthorizationStatus status) =>
    NotificationSettings(
      authorizationStatus: status,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.notSupported,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    );

void main() {
  late _MockMessaging messaging;
  late MockLocalNotificationService local;
  late StreamController<RemoteMessage> onMessage;
  late StreamController<RemoteMessage> onOpenedApp;
  late StreamController<String> onTokenRefresh;
  late List<String> tokens;
  late List<RemoteMessage> opened;
  late PushNotificationService service;

  const pushed = RemoteMessage(
    messageId: 'm1',
    notification: RemoteNotification(title: 'Hello', body: 'World'),
    data: {'route': '/inbox'},
  );

  setUp(() {
    messaging = _MockMessaging();
    local = MockLocalNotificationService();
    onMessage = StreamController();
    onOpenedApp = StreamController();
    onTokenRefresh = StreamController();
    tokens = [];
    opened = [];
    service = PushNotificationService(
      localNotifications: local,
      onToken: (token) async => tokens.add(token),
      onOpened: opened.add,
      messaging: messaging,
      onMessage: onMessage.stream,
      onMessageOpenedApp: onOpenedApp.stream,
    );

    when(
      () => messaging.setForegroundNotificationPresentationOptions(
        alert: any(named: 'alert'),
        badge: any(named: 'badge'),
        sound: any(named: 'sound'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => messaging.onTokenRefresh,
    ).thenAnswer((_) => onTokenRefresh.stream);
    when(messaging.getInitialMessage).thenAnswer((_) async => null);
    when(messaging.getToken).thenAnswer((_) async => 'token-1');
    when(
      messaging.getNotificationSettings,
    ).thenAnswer((_) async => _settings(AuthorizationStatus.notDetermined));
    when(
      () => local.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await service.dispose();
  });

  test('does not send a token before permission is granted', () async {
    await service.init();

    expect(tokens, isEmpty);
  });

  test('sends the token on startup when already authorized', () async {
    when(
      messaging.getNotificationSettings,
    ).thenAnswer((_) async => _settings(AuthorizationStatus.authorized));

    await service.init();

    expect(tokens, ['token-1']);
  });

  test('sends the token once permission is granted, and on refresh', () async {
    when(
      messaging.requestPermission,
    ).thenAnswer((_) async => _settings(AuthorizationStatus.provisional));
    await service.init();

    expect(await service.requestPermission(), isTrue);
    onTokenRefresh.add('token-2');
    await pumpEventQueue();

    expect(tokens, ['token-1', 'token-2']);
  });

  test('a denied permission sends no token', () async {
    when(
      messaging.requestPermission,
    ).thenAnswer((_) async => _settings(AuthorizationStatus.denied));

    expect(await service.requestPermission(), isFalse);
    expect(tokens, isEmpty);
  });

  test('reports the message that opened the app', () async {
    when(messaging.getInitialMessage).thenAnswer((_) async => pushed);

    await service.init();
    onOpenedApp.add(pushed);
    await pumpEventQueue();

    expect(opened, [pushed, pushed]);
  });

  test('shows foreground pushes as local notifications on Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await service.init();

    onMessage.add(pushed);
    await pumpEventQueue();

    verify(
      () => local.show(
        id: 'm1'.hashCode,
        title: 'Hello',
        body: 'World',
        payload: '/inbox',
      ),
    ).called(1);
  });

  test('leaves foreground pushes to the OS on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await service.init();

    onMessage.add(pushed);
    await pumpEventQueue();

    verifyNever(
      () => local.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    );
  });
}
```
