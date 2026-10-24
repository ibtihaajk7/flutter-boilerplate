import 'dart:convert';
import 'dart:io';

/// An optional module that `tool/slim.dart` can remove.
///
/// Code that belongs to a feature is marked in place, in whatever comment
/// syntax the file uses (`//`, `#`, `<!-- -->`):
///
/// - a line ending in the marker comment `slim:<feature>` is removed with it
/// - lines between `slim:<feature>:start` and `slim:<feature>:end` are
///   removed with it
///
/// Everything else a feature owns (files, packages, strings) is listed here.
enum SlimFeature {
  analytics(
    paths: [
      'lib/core/analytics',
      'test/core/analytics',
      'docs/recipes/analytics-firebase.md',
      'docs/recipes/analytics-mixpanel.md',
    ],
  ),
  crash(
    paths: ['lib/core/crash', 'test/core/crash', 'docs/recipes/crashlytics.md'],
  ),
  notifications(
    paths: [
      'lib/core/notifications',
      'lib/features/home/notification_card.dart',
      'test/core/notifications',
      'docs/recipes/push-fcm.md',
    ],
    packages: ['flutter_local_notifications', 'flutter_timezone', 'timezone'],
    arbKeys: [
      'notificationsTitle',
      'notificationsBody',
      'sendTestNotification',
      'testNotificationTitle',
      'testNotificationBody',
      'notificationsDenied',
      'notificationChannelName',
      'notificationChannelDescription',
    ],
  );

  const SlimFeature({
    required this.paths,
    this.packages = const [],
    this.arbKeys = const [],
  });

  /// Files and folders deleted with the feature.
  final List<String> paths;

  /// Packages removed from `pubspec.yaml`.
  final List<String> packages;

  /// Keys removed from every ARB file.
  final List<String> arbKeys;

  /// Parses a comma-separated list like `analytics,crash`.
  static Set<SlimFeature> parse(String names) {
    final features = <SlimFeature>{};
    for (final name in names.split(',').map((n) => n.trim())) {
      if (name.isEmpty) continue;
      final feature = SlimFeature.values.where((f) => f.name == name);
      if (feature.isEmpty) {
        throw FormatException(
          'Unknown feature "$name". '
          'Choose from: ${SlimFeature.values.map((f) => f.name).join(', ')}',
        );
      }
      features.add(feature.single);
    }
    return features;
  }
}

final _blockMarker = RegExp(r'slim:(\w+):(start|end)\b');
final _lineMarker = RegExp(r'\s*(?://|#|<!--)\s*slim:(\w+)\s*(?:-->)?\s*$');

/// Applies slim markers to [content].
///
/// Code marked for a feature in [removed] is dropped. Markers of kept
/// features stay, so the tool can run again later, unless [stripMarkers]
/// is set, which also removes the marker comments of kept features.
///
/// Throws [FormatException] on unbalanced block markers.
String applySlimMarkers(
  String content, {
  required Set<String> removed,
  bool stripMarkers = false,
}) {
  final output = <String>[];
  final open = <String>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final block = _blockMarker.firstMatch(line);
    if (block != null) {
      final feature = block.group(1)!;
      if (block.group(2) == 'start') {
        open.add(feature);
      } else if (open.isEmpty || open.removeLast() != feature) {
        throw FormatException('Unexpected end of "$feature" block', line, i);
      }
      final keep = !stripMarkers && !removed.contains(feature);
      if (keep && !open.any(removed.contains)) output.add(line);
      continue;
    }
    if (open.any(removed.contains)) continue;

    final marker = _lineMarker.firstMatch(line);
    if (marker == null) {
      output.add(line);
    } else if (!removed.contains(marker.group(1))) {
      output.add(stripMarkers ? line.substring(0, marker.start) : line);
    }
  }
  if (open.isNotEmpty) {
    throw FormatException('Unclosed "${open.last}" block');
  }
  return output.join('\n');
}

/// [arb] without [keys] and their `@key` metadata, in the original order.
String removeArbKeys(String arb, Iterable<String> keys) {
  final json = jsonDecode(arb) as Map<String, Object?>;
  for (final key in keys) {
    json
      ..remove(key)
      ..remove('@$key');
  }
  return '${const JsonEncoder.withIndent('  ').convert(json)}\n';
}

const _skippedDirectories = {
  '.git',
  '.dart_tool',
  '.idea',
  'build',
  'coverage',
  'Pods',
  'images',
};

/// Folders whose files talk about markers rather than use them.
const _unmarkedPaths = ['tool/', 'test/tool/'];

const _markedExtensions = {
  '.dart',
  '.md',
  '.yaml',
  '.yml',
  '.xml',
  '.kts',
  '.swift',
  '.arb',
};

/// Removes [features] from the project in [root]: files, marked code and
/// ARB keys. Returns the paths (relative to [root]) it changed or deleted.
///
/// Packages are not touched here; `tool/slim.dart` runs `flutter pub remove`.
List<String> slim(
  Directory root,
  Set<SlimFeature> features, {
  bool stripMarkers = false,
}) {
  final changed = <String>[];
  for (final path in features.expand((f) => f.paths)) {
    final entity = FileSystemEntity.typeSync('${root.path}/$path');
    if (entity == FileSystemEntityType.notFound) continue;
    if (entity == FileSystemEntityType.directory) {
      Directory('${root.path}/$path').deleteSync(recursive: true);
    } else {
      File('${root.path}/$path').deleteSync();
    }
    changed.add(path);
  }

  final removed = features.map((f) => f.name).toSet();
  final arbKeys = features.expand((f) => f.arbKeys).toList();
  for (final file in _markedFiles(root)) {
    final relative = file.path.substring(root.path.length + 1);
    final original = file.readAsStringSync();
    var updated = applySlimMarkers(
      original,
      removed: removed,
      stripMarkers: stripMarkers,
    );
    if (relative.endsWith('.arb') && arbKeys.isNotEmpty) {
      updated = removeArbKeys(updated, arbKeys);
    }
    if (updated != original) {
      file.writeAsStringSync(updated);
      changed.add(relative);
    }
  }
  return changed..sort();
}

Iterable<File> _markedFiles(Directory root) sync* {
  final pending = [root];
  while (pending.isNotEmpty) {
    for (final entity in pending.removeLast().listSync()) {
      final relative = entity.path.substring(root.path.length + 1);
      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (entity is Directory) {
        if (!_skippedDirectories.contains(name) &&
            !_unmarkedPaths.contains('$relative/')) {
          pending.add(entity);
        }
      } else if (entity is File &&
          _markedExtensions.any(name.endsWith) &&
          !_unmarkedPaths.any(relative.startsWith)) {
        yield entity;
      }
    }
  }
}
