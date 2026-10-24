import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app.dart';
import 'package:flutter_boilerplate/core/env/app_env.dart';
import 'package:flutter_boilerplate/features/home/counter_controller.dart';
import 'package:provider/provider.dart';

// Keep main() to the bare minimum needed to reach the first frame.
// Everything slow is started after runApp, in _deferredInit.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppEnv.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CounterController(),
        ),
      ],
      child: const App(),
    ),
  );

  unawaited(
    _deferredInit({}),
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
