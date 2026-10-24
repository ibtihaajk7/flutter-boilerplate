// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Boilerplate';

  @override
  String get homeTitle => 'Home';

  @override
  String get welcomeHeadline => 'Welcome';

  @override
  String get welcomeBody =>
      'This screen is built with Rows and Columns, SafeScale sizes and localized strings. Replace it with your first feature.';

  @override
  String counterLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tapped $count times',
      one: 'Tapped once',
      zero: 'No taps yet',
    );
    return '$_temp0';
  }

  @override
  String get incrementTooltip => 'Increment';

  @override
  String get reset => 'Reset';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsBody =>
      'Local notifications work out of the box, no server needed. Permission is asked only when you tap.';

  @override
  String get sendTestNotification => 'Send a test notification';

  @override
  String get testNotificationTitle => 'It works!';

  @override
  String get testNotificationBody =>
      'This notification came from your new app.';

  @override
  String get notificationsDenied =>
      'Notifications are off. You can turn them on in Settings.';

  @override
  String get notificationChannelName => 'General';

  @override
  String get notificationChannelDescription =>
      'General notifications from the app.';
}
