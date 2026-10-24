// Removes optional modules you don't need, leaving a lean, green project.
//
//   dart run tool/slim.dart --without analytics,crash,notifications
//   dart run tool/slim.dart --strip-markers   (keep everything, drop markers)
//
// Safe to run again later: markers of the modules you keep stay in place
// unless you pass --strip-markers.
import 'dart:io';

import 'src/slimmer.dart';

void main(List<String> arguments) {
  final withoutIndex = arguments.indexOf('--without');
  final stripMarkers = arguments.contains('--strip-markers');
  if (arguments.contains('--help') ||
      (withoutIndex == -1 && !stripMarkers) ||
      (withoutIndex != -1 && withoutIndex + 1 >= arguments.length)) {
    stdout.writeln(
      'Usage: dart run tool/slim.dart --without <modules> [--strip-markers]\n'
      'Modules: ${SlimFeature.values.map((f) => f.name).join(', ')}',
    );
    exitCode = arguments.contains('--help') ? 0 : 64;
    return;
  }

  final Set<SlimFeature> features;
  try {
    features = withoutIndex == -1
        ? {}
        : SlimFeature.parse(arguments[withoutIndex + 1]);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
    return;
  }

  final changed = slim(Directory.current, features, stripMarkers: stripMarkers);
  final packages = features.expand((f) => f.packages).toList();
  final tidied =
      (packages.isEmpty || _run('flutter', ['pub', 'remove', ...packages])) &&
      _run('flutter', ['pub', 'get']) &&
      _run('flutter', ['gen-l10n']) &&
      _run('dart', ['fix', '--apply']) &&
      // Twice: removed blocks can leave layout that only settles on a second
      // pass (e.g. a comment that ends up last in a file).
      _run('dart', ['format', 'lib', 'test', 'tool']) &&
      _run('dart', ['format', 'lib', 'test', 'tool']);

  stdout
    ..writeln(
      features.isEmpty
          ? 'Removed slim markers.'
          : 'Removed ${features.map((f) => f.name).join(', ')}.',
    )
    ..writeln('  ${changed.length} files changed or deleted.')
    ..writeln()
    ..writeln(
      tidied
          ? 'Next: make check'
          : 'Next: fix the step above, then dart fix --apply && make check',
    );
}

bool _run(String executable, List<String> arguments) {
  final result = Process.runSync(
    executable,
    arguments,
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    stderr
      ..writeln('$executable ${arguments.join(' ')} failed:')
      ..write(result.stderr);
  }
  return result.exitCode == 0;
}
