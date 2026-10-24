# Crashlytics

Requires [Firebase setup](firebase-setup.md).

```bash
flutter pub add firebase_crashlytics
```
```bash
flutterfire configure --platforms=android,ios
```

Running `flutterfire configure` again adds the Crashlytics Gradle plugin and
the Xcode build phase that uploads dSYMs, so iOS stack traces are readable.

## Add the reporter

Save as `lib/core/crash/crashlytics_crash_reporter.dart`:

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/crash/crash_reporter.dart';

class CrashlyticsCrashReporter implements CrashReporter {
  CrashlyticsCrashReporter({FirebaseCrashlytics? crashlytics})
    : _injected = crashlytics;

  final FirebaseCrashlytics? _injected;

  // Resolved lazily: FirebaseCrashlytics.instance needs Firebase.initializeApp.
  FirebaseCrashlytics get _crashlytics =>
      _injected ?? FirebaseCrashlytics.instance;

  /// Debug runs never send reports, so the dashboard only shows real users.
  @override
  Future<void> init() =>
      _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) => _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> setUserId(String? id) =>
      _crashlytics.setUserIdentifier(id ?? '');

  @override
  Future<void> setEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);
}
```

## Register it

In `lib/main.dart`, after `Firebase.initializeApp`:

```dart
final CrashReporter crashReporter = kDebugMode
    ? DebugCrashReporter()
    : CrashlyticsCrashReporter();
installErrorHandlers(crashReporter);
```

`installErrorHandlers` already routes every uncaught Flutter and async error
to it. Report caught errors yourself with
`context.read<CrashReporter>().recordError(error, stack, reason: '…')`.

## Verify it

Crashlytics only shows a crash after the app restarts. Build in release, add
a temporary button that throws, tap it, reopen the app, and check the console
after a few minutes.

## Obfuscated builds

If you build with `--obfuscate --split-debug-info=build/symbols`, upload the
symbols so traces are readable:

```bash
firebase crashlytics:symbols:upload --app=<your-firebase-app-id> build/symbols
```

### Test it

Save as `test/core/crash/crashlytics_crash_reporter_test.dart`. It runs with `make check` like every other test.

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_boilerplate/core/crash/crashlytics_crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late _MockCrashlytics crashlytics;
  late CrashlyticsCrashReporter reporter;

  setUp(() {
    crashlytics = _MockCrashlytics();
    reporter = CrashlyticsCrashReporter(crashlytics: crashlytics);
    when(
      () => crashlytics.setCrashlyticsCollectionEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => crashlytics.recordError(
        any<Object>(),
        any(),
        reason: any<Object?>(named: 'reason'),
        fatal: any(named: 'fatal'),
      ),
    ).thenAnswer((_) async {});
    when(() => crashlytics.log(any())).thenAnswer((_) async {});
    when(() => crashlytics.setUserIdentifier(any())).thenAnswer((_) async {});
  });

  test('init keeps debug runs out of the dashboard', () async {
    await reporter.init();

    // Tests run in debug mode.
    verify(() => crashlytics.setCrashlyticsCollectionEnabled(false)).called(1);
  });

  test('maps every call onto Crashlytics', () async {
    await reporter.recordError(
      'boom',
      StackTrace.empty,
      reason: 'loading',
      fatal: true,
    );
    await reporter.log('opened settings');
    await reporter.setUserId('u1');
    await reporter.setUserId(null);
    await reporter.setEnabled(true);

    verify(
      () => crashlytics.recordError(
        'boom',
        StackTrace.empty,
        reason: 'loading',
        fatal: true,
      ),
    ).called(1);
    verify(() => crashlytics.log('opened settings')).called(1);
    verify(() => crashlytics.setUserIdentifier('u1')).called(1);
    verify(() => crashlytics.setUserIdentifier('')).called(1);
    verify(() => crashlytics.setCrashlyticsCollectionEnabled(true)).called(1);
  });
}
```
