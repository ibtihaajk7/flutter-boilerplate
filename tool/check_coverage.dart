// Fails if line coverage of lib/ drops below the minimum, or if any file
// under lib/ has no test loading it at all.
//
//   flutter test --coverage && dart run tool/check_coverage.dart [--min 80]
import 'dart:io';

import 'src/coverage.dart';

/// Not worth unit testing: app bootstrap and generated localizations.
const _excluded = ['lib/main.dart', 'lib/l10n/'];
const _defaultMin = 80.0;
const _ignoreFileMarker = '// coverage:ignore-file';

void main(List<String> arguments) {
  final minIndex = arguments.indexOf('--min');
  final minPercent = minIndex != -1 && minIndex + 1 < arguments.length
      ? double.parse(arguments[minIndex + 1])
      : _defaultMin;

  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln('coverage/lcov.info not found. Run flutter test --coverage');
    exitCode = 1;
    return;
  }

  final libFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
  final report = evaluateCoverage(
    coverage: parseLcov(lcov.readAsStringSync()),
    libFiles: libFiles.map((file) => file.path).toList(),
    excluded: [
      ..._excluded,
      // Files with nothing to execute (constants only) opt out explicitly.
      for (final file in libFiles)
        if (file.readAsStringSync().contains(_ignoreFileMarker)) file.path,
    ],
    minPercent: minPercent,
  );

  final summary =
      'Coverage ${report.percent.toStringAsFixed(1)}% '
      '(minimum ${minPercent.toStringAsFixed(0)}%)';
  if (report.passes) {
    stdout.writeln('$summary OK');
    return;
  }
  stderr.writeln(summary);
  if (report.untestedFiles.isNotEmpty) {
    stderr
      ..writeln('No test loads these files:')
      ..writeln(report.untestedFiles.map((path) => '  $path').join('\n'));
  }
  exitCode = 1;
}
