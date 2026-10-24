import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// On-device notifications: shown now or scheduled daily. No server and no
/// Firebase needed. For push notifications see `docs/recipes/push-fcm.md`.
///
/// Permission is never requested on launch. Ask with [requestPermission]
/// when the user turns on something that needs it.
class LocalNotificationService {
  LocalNotificationService({
    required String channelName,
    required String channelDescription,
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? localTimezone,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _localTimezone = localTimezone ?? _deviceTimezone,
       _details = NotificationDetails(
         android: AndroidNotificationDetails(
           'general',
           channelName,
           channelDescription: channelDescription,
           importance: Importance.high,
           priority: Priority.high,
         ),
         iOS: const DarwinNotificationDetails(),
       );

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<String> Function() _localTimezone;
  final NotificationDetails _details;

  /// Replace with a monochrome `ic_notification` drawable for production.
  static const String androidIcon = '@mipmap/ic_launcher';

  /// Sets up timezones and the plugin. [onTap] receives the payload of a
  /// notification the user tapped.
  Future<void> init({void Function(String? payload)? onTap}) async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await _localTimezone()));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(androidIcon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
  }

  /// Asks the OS for permission. Returns whether notifications are allowed.
  Future<bool> requestPermission() async {
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      TargetPlatform.iOS =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true),
      _ => false,
    };
    return granted ?? false;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) => _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: _details,
    payload: payload,
  );

  /// Shows a notification every day at [hour]:[minute] device time.
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
  }) => _plugin.zonedSchedule(
    id: id,
    scheduledDate: nextInstanceOf(hour, minute, tz.TZDateTime.now(tz.local)),
    notificationDetails: _details,
    // Inexact needs no extra permission and is fine for reminders.
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    title: title,
    body: body,
    payload: payload,
  );

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();

  /// The next [hour]:[minute] after [now]: today if still ahead, else
  /// tomorrow.
  ///
  /// Tomorrow is built from the calendar date, not `today + 24h`, so the
  /// wall-clock time survives daylight-saving changes.
  static tz.TZDateTime nextInstanceOf(int hour, int minute, tz.TZDateTime now) {
    tz.TZDateTime at(int dayOffset) => tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + dayOffset,
      hour,
      minute,
    );
    final today = at(0);
    return today.isAfter(now) ? today : at(1);
  }

  // coverage:ignore-start
  static Future<String> _deviceTimezone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;
  // coverage:ignore-end
}
