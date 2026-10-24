import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/notifications/local_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroid extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockIos extends Mock implements IOSFlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  late LocalNotificationService service;

  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);
    tz.initializeTimeZones();
    registerFallbackValue(tz.TZDateTime.utc(2026));
  });

  setUp(() {
    plugin = _MockPlugin();
    service = LocalNotificationService(
      channelName: 'General',
      channelDescription: 'General notifications',
      plugin: plugin,
      localTimezone: () async => 'Europe/Paris',
    );
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('init sets the local timezone and forwards taps', () async {
    DidReceiveNotificationResponseCallback? onResponse;
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((invocation) async {
      onResponse =
          invocation.namedArguments[#onDidReceiveNotificationResponse]
              as DidReceiveNotificationResponseCallback?;
      return true;
    });
    final taps = <String?>[];

    await service.init(onTap: taps.add);
    onResponse!(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'open_settings',
      ),
    );

    expect(tz.local.name, 'Europe/Paris');
    expect(taps, ['open_settings']);
  });

  group('requestPermission', () {
    test('asks Android for POST_NOTIFICATIONS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = _MockAndroid();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        android.requestNotificationsPermission,
      ).thenAnswer((_) async => true);

      expect(await service.requestPermission(), isTrue);
    });

    test('asks iOS for alert, badge and sound', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ios = _MockIos();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(ios);
      when(
        () => ios.requestPermissions(alert: true, badge: true, sound: true),
      ).thenAnswer((_) async => false);

      expect(await service.requestPermission(), isFalse);
    });

    test('is false on platforms without notifications', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      expect(await service.requestPermission(), isFalse);
    });
  });

  test('show forwards to the plugin', () async {
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    await service.show(id: 1, title: 'Hi', body: 'There', payload: 'p');

    verify(
      () => plugin.show(
        id: 1,
        title: 'Hi',
        body: 'There',
        notificationDetails: any(named: 'notificationDetails'),
        payload: 'p',
      ),
    ).called(1);
  });

  test('scheduleDaily repeats at the same time every day', () async {
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    await service.scheduleDaily(
      id: 2,
      hour: 20,
      minute: 30,
      title: 'Reminder',
      body: 'Come back',
    );

    final scheduled =
        verify(
              () => plugin.zonedSchedule(
                id: 2,
                scheduledDate: captureAny(named: 'scheduledDate'),
                notificationDetails: any(named: 'notificationDetails'),
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                matchDateTimeComponents: DateTimeComponents.time,
                title: 'Reminder',
                body: 'Come back',
              ),
            ).captured.single
            as tz.TZDateTime;
    expect((scheduled.hour, scheduled.minute), (20, 30));
  });

  test('cancel and cancelAll forward to the plugin', () async {
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    when(plugin.cancelAll).thenAnswer((_) async {});

    await service.cancel(3);
    await service.cancelAll();

    verify(() => plugin.cancel(id: 3)).called(1);
    verify(plugin.cancelAll).called(1);
  });

  group('nextInstanceOf', () {
    late tz.Location paris;

    setUp(() => paris = tz.getLocation('Europe/Paris'));

    test('is today when the time is still ahead', () {
      final now = tz.TZDateTime(paris, 2026, 10, 24, 9);

      expect(
        LocalNotificationService.nextInstanceOf(20, 0, now),
        tz.TZDateTime(paris, 2026, 10, 24, 20),
      );
    });

    test('is tomorrow when the time has passed or is now', () {
      final now = tz.TZDateTime(paris, 2026, 10, 24, 20);

      expect(
        LocalNotificationService.nextInstanceOf(20, 0, now),
        tz.TZDateTime(paris, 2026, 10, 25, 20),
      );
    });
  });
}
