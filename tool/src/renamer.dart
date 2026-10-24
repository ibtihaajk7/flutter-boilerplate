import 'dart:io';

/// Identifiers `flutter create` produced for this template. The renamer
/// swaps them for the new project's.
const templateName = 'flutter_boilerplate';
const templateOrg = 'com.example';
const templateDisplayName = 'Flutter Boilerplate';

/// Files that only make sense inside the template; deleted after a rename.
const templateOnlyPaths = [
  'tool/rename.dart',
  'tool/src/renamer.dart',
  'test/tool/renamer_test.dart',
];

/// Folders that only make sense inside the template (README images);
/// deleted after a rename.
const templateOnlyDirectories = ['docs/images'];

const _skippedDirectories = {
  '.git',
  '.dart_tool',
  '.idea',
  'build',
  'coverage',
  'Pods',
};

const _binaryExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.ico',
  '.ttf',
  '.otf',
  '.jar',
  '.keystore',
  '.jks',
  '.zip',
};

const _reservedWords = {
  'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch', //
  'class', 'const', 'continue', 'default', 'do', 'else', 'enum', 'export',
  'extends', 'false', 'final', 'finally', 'for', 'if', 'import', 'in', 'is',
  'new', 'null', 'return', 'super', 'switch', 'this', 'throw', 'true', 'try',
  'var', 'void', 'while', 'with', 'flutter', 'test',
};

final _templateBlock = RegExp(
  r'^[^\n]*template:start[^\n]*\n[\s\S]*?^[^\n]*template:end[^\n]*\n\n?',
  multiLine: true,
);

class RenameConfig {
  const RenameConfig({
    required this.name,
    required this.org,
    required this.displayName,
  });

  /// Dart package name, e.g. `my_app`.
  final String name;

  /// Reverse-domain organization, e.g. `com.acme`.
  final String org;

  /// Name shown under the app icon, e.g. `My App`.
  final String displayName;

  /// Android application ID: underscores are allowed.
  String get androidId => '$org.$name';

  /// iOS bundle ID: no underscores, so the name is camelCased the same way
  /// `flutter create` does it.
  String get iosBundleId => '$org.${toCamelCase(name)}';

  /// Every problem with this config; empty when it is valid.
  List<String> validate() => [
    if (!RegExp(r'^[a-z][a-z0-9_]*[a-z0-9]$').hasMatch(name))
      '--name must be snake_case (a-z, 0-9, _), e.g. my_app',
    if (_reservedWords.contains(name)) '--name "$name" is a reserved word',
    if (!RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$').hasMatch(org))
      '--org must be a reverse domain like com.acme (lowercase, no _)',
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9 ._-]{0,29}$').hasMatch(displayName))
      '--display must be 1-30 letters, digits, spaces, ".", "_" or "-"',
  ];
}

String toCamelCase(String snake) {
  final parts = snake.split('_');
  return parts.first +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

/// Renames a fresh copy of the template in [root] to a new project.
class Renamer {
  Renamer(this.root);

  final Directory root;

  /// Applies [config] and returns the paths (relative to [root]) it changed.
  ///
  /// Throws [StateError] if [root] is not an unrenamed template.
  List<String> rename(RenameConfig config) {
    final problems = config.validate();
    if (problems.isNotEmpty) {
      throw ArgumentError(problems.join('\n'));
    }
    final pubspec = File(_path('pubspec.yaml'));
    if (!pubspec.existsSync() ||
        !pubspec.readAsStringSync().contains('name: $templateName\n')) {
      throw StateError(
        'Run this from the root of an unrenamed $templateName checkout.',
      );
    }

    // Most specific first, so a shorter match never eats part of a longer one.
    final replacements = <(String, String)>[
      ('$templateOrg.${toCamelCase(templateName)}', config.iosBundleId),
      ('$templateOrg.$templateName', config.androidId),
      (
        'android:label="$templateName"',
        'android:label="${config.displayName}"',
      ),
      (templateDisplayName, config.displayName),
      (templateName, config.name),
    ];

    final changed = <String>[];
    for (final file in _textFiles()) {
      final relative = _relative(file.path);
      final original = file.readAsStringSync();
      var updated = original.replaceAll(_templateBlock, '');
      for (final (from, to) in replacements) {
        updated = updated.replaceAll(from, to);
      }
      if (updated != original) {
        file.writeAsStringSync(updated);
        changed.add(relative);
      }
    }

    _moveKotlinPackage(config);
    for (final path in templateOnlyPaths) {
      final file = File(_path(path));
      if (file.existsSync()) file.deleteSync();
    }
    for (final path in templateOnlyDirectories) {
      final directory = Directory(_path(path));
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    }
    return changed..sort();
  }

  void _moveKotlinPackage(RenameConfig config) {
    final kotlinRoot = _path('android/app/src/main/kotlin');
    final from = Directory(
      [kotlinRoot, ...'$templateOrg.$templateName'.split('.')].join('/'),
    );
    if (!from.existsSync()) return;
    final to = Directory([kotlinRoot, ...config.androidId.split('.')].join('/'))
      ..createSync(recursive: true);
    for (final entity in from.listSync()) {
      entity.renameSync('${to.path}/${entity.uri.pathSegments.last}');
    }
    // Remove the now-empty template package folders.
    var dir = from;
    while (dir.path != kotlinRoot && dir.listSync().isEmpty) {
      dir.deleteSync();
      dir = dir.parent;
    }
  }

  Iterable<File> _textFiles() sync* {
    final pending = [root];
    while (pending.isNotEmpty) {
      for (final entity in pending.removeLast().listSync()) {
        final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
        if (entity is Directory) {
          if (!_skippedDirectories.contains(name)) pending.add(entity);
        } else if (entity is File &&
            !templateOnlyPaths.contains(_relative(entity.path)) &&
            !_binaryExtensions.any(name.toLowerCase().endsWith)) {
          yield entity;
        }
      }
    }
  }

  String _path(String relative) => '${root.path}/$relative';

  String _relative(String path) => path.substring(root.path.length + 1);
}
