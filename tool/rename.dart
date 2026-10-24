// Renames this template to your project, like `flutter create` would.
//
//   dart run tool/rename.dart --name my_app --org com.acme --display "My App"
//
// Run it once, from the repo root, on a fresh copy. It deletes itself when
// done.
import 'dart:io';

import 'src/renamer.dart';

void main(List<String> arguments) {
  final options = _parse(arguments);
  final name = options['name'];
  final org = options['org'];
  if (options.containsKey('help') || name == null || org == null) {
    stdout.writeln(
      'Usage: dart run tool/rename.dart --name my_app --org com.acme '
      '[--display "My App"]',
    );
    exitCode = options.containsKey('help') ? 0 : 64;
    return;
  }

  final config = RenameConfig(
    name: name,
    org: org,
    displayName: options['display'] ?? _titleCase(name),
  );
  final problems = config.validate();
  if (problems.isNotEmpty) {
    stderr.writeln(problems.join('\n'));
    exitCode = 64;
    return;
  }

  final List<String> changed;
  try {
    changed = Renamer(Directory.current).rename(config);
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
    return;
  }

  // The new package name can change import order; leave the tree lint-clean.
  final tidied =
      _run('flutter', ['pub', 'get']) &&
      _run('dart', ['fix', '--apply', '--code=directives_ordering']) &&
      _run('dart', ['format', 'lib', 'test', 'tool']);

  stdout
    ..writeln('Renamed to ${config.name} (${config.displayName}).')
    ..writeln('  Android: ${config.androidId}')
    ..writeln('  iOS:     ${config.iosBundleId}')
    ..writeln('  ${changed.length} files updated.')
    ..writeln()
    ..writeln(
      tidied
          ? 'Next: make check'
          : 'Next: flutter pub get && dart fix --apply && make check',
    );
}

bool _run(String executable, List<String> arguments) {
  final result = Process.runSync(
    executable,
    arguments,
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    stderr.writeln('$executable ${arguments.join(' ')} failed:');
    stderr.write(result.stderr);
  }
  return result.exitCode == 0;
}

Map<String, String> _parse(List<String> arguments) {
  final options = <String, String>{};
  for (var i = 0; i < arguments.length; i++) {
    final argument = arguments[i];
    if (!argument.startsWith('--')) continue;
    final flag = argument.substring(2);
    final equals = flag.indexOf('=');
    if (equals != -1) {
      options[flag.substring(0, equals)] = flag.substring(equals + 1);
    } else if (i + 1 < arguments.length && !arguments[i + 1].startsWith('--')) {
      options[flag] = arguments[++i];
    } else {
      options[flag] = '';
    }
  }
  return options;
}

String _titleCase(String snake) => snake
    .split('_')
    .map((part) => part[0].toUpperCase() + part.substring(1))
    .join(' ');
