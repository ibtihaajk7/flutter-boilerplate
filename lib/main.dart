import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/analytics/debug_analytics_provider.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/crash/crash_reporter.dart'; // slim:crash
import 'package:flutter_boilerplate/core/env/app_env.dart';
import 'package:flutter_boilerplate/core/l10n/l10n.dart';
import 'package:flutter_boilerplate/core/notifications/local_notification_service.dart'; // slim:notifications
import 'package:flutter_boilerplate/features/home/counter_controller.dart';
import 'package:flutter_boilerplate/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

// Keep main() to the bare minimum needed to reach the first frame.
// Everything slow is started after runApp, in _deferredInit.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // slim:crash:start
  // Swap in a vendor here: docs/recipes/crashlytics.md
  final CrashReporter crashReporter = DebugCrashReporter();
  installErrorHandlers(crashReporter);
  // slim:crash:end

  await AppEnv.load();

  // slim:analytics:start
  // Add vendors to the list: docs/recipes/analytics-*.md
  final analytics = AnalyticsService([DebugAnalyticsProvider()]);
  // slim:analytics:end

  // slim:notifications:start
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
  // slim:notifications:end

  runApp(
    MultiProvider(
      providers: [
        Provider<CrashReporter>.value(value: crashReporter), // slim:crash
        Provider<AnalyticsService>.value(value: analytics), // slim:analytics
        // slim:notifications:start
        Provider<LocalNotificationService>.value(
          value: notifications,
        ),
        // slim:notifications:end
        ChangeNotifierProvider(
          create: (_) => CounterController(
            analytics, // slim:analytics
          ),
        ),
      ],
      child: const App(),
    ),
  );

  unawaited(
    _deferredInit({
      'crash reporter': crashReporter.init, // slim:crash
      'analytics': analytics.init, // slim:analytics
      'notifications': notifications.init, // slim:notifications
    }),
  );
}

/// Runs each step on its own, so one failing SDK can't take down the rest.
/// Failures go through `FlutterError.reportError`, which reaches the crash
/// reporter when one is installed.
Future<void> _deferredInit(Map<String, Future<void> Function()> steps) async {
  for (final MapEntry(key: name, value: step) in steps.entries) {
    try {
      await step();
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          context: ErrorDescription('while initializing $name'),
        ),
      );
    }
  }
}
