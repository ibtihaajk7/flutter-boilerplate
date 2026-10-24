import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart';
import 'package:flutter_boilerplate/core/analytics/debug_analytics_provider.dart';
import 'package:flutter_boilerplate/core/crash/crash_reporter.dart';
import 'package:flutter_boilerplate/core/env/app_env.dart';
import 'package:flutter_boilerplate/core/l10n/l10n.dart';
import 'package:flutter_boilerplate/core/notifications/local_notification_service.dart';
import 'package:flutter_boilerplate/features/home/counter_controller.dart';
import 'package:flutter_boilerplate/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

// Keep main() to the bare minimum needed to reach the first frame.
// Everything slow is started after runApp, in _deferredInit.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Swap in a vendor here: docs/recipes/crashlytics.md
  final CrashReporter crashReporter = DebugCrashReporter();
  installErrorHandlers(crashReporter);

  await AppEnv.load();

  // Add vendors to the list: docs/recipes/analytics-*.md
  final analytics = AnalyticsService([DebugAnalyticsProvider()]);

  // Outside the widget tree there is no localeResolutionCallback, so resolve
  // the device locale first: lookupAppLocalizations throws on unsupported
  // languages.
  final l10n = lookupAppLocalizations(
    resolveLocale(
      PlatformDispatcher.instance.locale,
      AppLocalizations.supportedLocales,
    ),
  );
  final notifications = LocalNotificationService(
    channelName: l10n.notificationChannelName,
    channelDescription: l10n.notificationChannelDescription,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<CrashReporter>.value(value: crashReporter),
        Provider<AnalyticsService>.value(value: analytics),
        Provider<LocalNotificationService>.value(value: notifications),
        ChangeNotifierProvider(
          create: (_) => CounterController(analytics: analytics),
        ),
      ],
      child: const App(),
    ),
  );

  unawaited(_deferredInit(crashReporter, analytics, notifications));
}

/// Each step is guarded on its own so one failing SDK can't take down the
/// rest.
Future<void> _deferredInit(
  CrashReporter crashReporter,
  AnalyticsService analytics,
  LocalNotificationService notifications,
) async {
  final steps = <String, Future<void> Function()>{
    'crash reporter': crashReporter.init,
    'analytics': analytics.init,
    'notifications': notifications.init,
  };
  for (final MapEntry(key: name, value: step) in steps.entries) {
    try {
      await step();
    } on Object catch (error, stack) {
      await crashReporter.recordError(error, stack, reason: '$name init');
    }
  }
}
