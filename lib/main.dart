import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app.dart';
import 'package:flutter_boilerplate/core/env/app_env.dart';
import 'package:flutter_boilerplate/features/home/counter_controller.dart';
import 'package:provider/provider.dart';

// Keep main() to the bare minimum needed to reach the first frame.
// Heavy or network-bound setup belongs in a deferred init after runApp.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppEnv.load();

  // Hook crash reporting here (FlutterError.onError and
  // PlatformDispatcher.instance.onError) once you add a provider.

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CounterController())],
      child: const App(),
    ),
  );
}
