import 'package:flutter/foundation.dart';

/// One crash-reporting backend (Crashlytics, Sentry…). See
/// `docs/recipes/crashlytics.md`.
abstract interface class CrashReporter {
  Future<void> init();

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });

  /// Breadcrumb attached to the next report.
  Future<void> log(String message);

  /// `null` clears the user (sign-out).
  Future<void> setUserId(String? id);

  Future<void> setEnabled(bool enabled);
}

/// Prints errors to the console. The default reporter until a vendor is set
/// up.
class DebugCrashReporter implements CrashReporter {
  DebugCrashReporter({void Function(String message)? log})
    : _log = log ?? debugPrint;

  final void Function(String message) _log;

  @override
  Future<void> init() async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    _log(
      '[crash${fatal ? ' fatal' : ''}] ${reason ?? 'error'}: $error'
      '${stack == null ? '' : '\n$stack'}',
    );
  }

  @override
  Future<void> log(String message) async => _log('[crash log] $message');

  @override
  Future<void> setUserId(String? id) async => _log('[crash] user $id');

  @override
  Future<void> setEnabled(bool enabled) async =>
      _log('[crash] enabled $enabled');
}

/// Routes every uncaught Flutter and platform error to [reporter].
///
/// Call once in `main()`, right after `WidgetsFlutterBinding.ensureInitialized`.
/// In debug builds errors are still printed to the console as usual.
void installErrorHandlers(CrashReporter reporter) {
  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    reporter
        .recordError(
          details.exception,
          details.stack,
          reason: details.context?.toDescription(),
          fatal: true,
        )
        .ignore();
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.recordError(error, stack, fatal: true).ignore();
    return true;
  };
}
