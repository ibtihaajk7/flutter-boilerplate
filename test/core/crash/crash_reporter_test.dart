import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/crash/crash_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCrashReporter extends Mock implements CrashReporter {}

void main() {
  group('DebugCrashReporter', () {
    test('logs errors, breadcrumbs and user changes', () async {
      final lines = <String>[];
      final reporter = DebugCrashReporter(log: lines.add);

      await reporter.init();
      await reporter.recordError('boom', null, reason: 'loading');
      await reporter.recordError('fatal boom', StackTrace.empty, fatal: true);
      await reporter.log('opened settings');
      await reporter.setUserId('u1');
      await reporter.setEnabled(false);

      expect(lines, [
        '[crash] loading: boom',
        '[crash fatal] error: fatal boom\n',
        '[crash log] opened settings',
        '[crash] user u1',
        '[crash] enabled false',
      ]);
    });

    test('defaults to debugPrint', () async {
      await expectLater(DebugCrashReporter().log('hi'), completes);
    });
  });

  group('installErrorHandlers', () {
    late FlutterExceptionHandler? flutterOnError;
    late ErrorCallback? platformOnError;
    late _MockCrashReporter reporter;

    setUp(() {
      flutterOnError = FlutterError.onError;
      platformOnError = PlatformDispatcher.instance.onError;
      reporter = _MockCrashReporter();
      when(
        () => reporter.recordError(
          any<Object>(),
          any(),
          reason: any(named: 'reason'),
          fatal: any(named: 'fatal'),
        ),
      ).thenAnswer((_) async {});
      installErrorHandlers(reporter);
    });

    tearDown(() {
      FlutterError.onError = flutterOnError;
      PlatformDispatcher.instance.onError = platformOnError;
    });

    test('reports Flutter framework errors as fatal', () {
      FlutterError.onError!(
        FlutterErrorDetails(
          exception: 'layout failed',
          stack: StackTrace.empty,
          context: ErrorDescription('while testing'),
          silent: true,
        ),
      );

      verify(
        () => reporter.recordError(
          'layout failed',
          StackTrace.empty,
          reason: 'while testing',
          fatal: true,
        ),
      ).called(1);
    });

    test('reports uncaught async errors as fatal and handles them', () {
      final handled = PlatformDispatcher.instance.onError!(
        'async boom',
        StackTrace.empty,
      );

      expect(handled, isTrue);
      verify(
        () => reporter.recordError('async boom', StackTrace.empty, fatal: true),
      ).called(1);
    });
  });
}
