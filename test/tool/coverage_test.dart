import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/coverage.dart';

const _lcov = '''
SF:lib/app.dart
DA:1,1
LF:10
LH:9
end_of_record
SF:/home/runner/work/app/lib/l10n/app_localizations.dart
LF:100
LH:0
end_of_record
''';

void main() {
  test('parseLcov reads files and normalizes paths to lib/', () {
    final files = parseLcov(_lcov);

    expect(files.map((file) => file.path), [
      'lib/app.dart',
      'lib/l10n/app_localizations.dart',
    ]);
    expect(files.first.linesFound, 10);
    expect(files.first.linesHit, 9);
  });

  test('excluded paths do not count against the total', () {
    final report = evaluateCoverage(
      coverage: parseLcov(_lcov),
      libFiles: ['lib/app.dart', 'lib/l10n/app_localizations.dart'],
      excluded: ['lib/l10n/'],
      minPercent: 80,
    );

    expect(report.percent, 90);
    expect(report.passes, isTrue);
  });

  test('fails below the minimum', () {
    final report = evaluateCoverage(
      coverage: parseLcov(_lcov),
      libFiles: ['lib/app.dart'],
      excluded: ['lib/l10n/'],
      minPercent: 95,
    );

    expect(report.passes, isFalse);
  });

  test('fails when a lib file has no test loading it', () {
    final report = evaluateCoverage(
      coverage: parseLcov(_lcov),
      libFiles: ['lib/app.dart', 'lib/forgotten.dart'],
      excluded: ['lib/l10n/'],
      minPercent: 80,
    );

    expect(report.untestedFiles, ['lib/forgotten.dart']);
    expect(report.passes, isFalse);
  });

  test('an empty report counts as fully covered', () {
    final report = evaluateCoverage(
      coverage: const [],
      libFiles: const [],
      excluded: const [],
      minPercent: 80,
    );

    expect(report.percent, 100);
    expect(report.passes, isTrue);
  });
}
