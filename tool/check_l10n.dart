// Fails if the ARB files drift apart: missing or extra keys, lost
// placeholders, or duplicate English copy.
//
//   dart run tool/check_l10n.dart
import 'dart:convert';
import 'dart:io';

import 'src/arb_checker.dart';

const _arbDirectory = 'lib/l10n';
const _template = 'app_en.arb';

void main() {
  final arbs = <String, Map<String, Object?>>{
    for (final file in Directory(_arbDirectory).listSync().whereType<File>())
      if (file.path.endsWith('.arb'))
        file.uri.pathSegments.last:
            jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
  };

  final problems = findArbProblems(arbs, template: _template);
  if (problems.isEmpty) {
    stdout.writeln('l10n OK: ${arbs.length} ARB files in sync.');
    return;
  }
  stderr.writeln(problems.join('\n'));
  exitCode = 1;
}
