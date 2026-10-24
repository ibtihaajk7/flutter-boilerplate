/// Line coverage of one source file, from an lcov report.
class FileCoverage {
  const FileCoverage({
    required this.path,
    required this.linesFound,
    required this.linesHit,
  });

  final String path;
  final int linesFound;
  final int linesHit;
}

class CoverageReport {
  const CoverageReport({
    required this.percent,
    required this.untestedFiles,
    required this.minPercent,
  });

  final double percent;

  /// Files under `lib/` that no test loads at all. lcov omits them, so
  /// without this check they would not count against the total.
  final List<String> untestedFiles;
  final double minPercent;

  bool get passes => percent >= minPercent && untestedFiles.isEmpty;
}

/// Parses `coverage/lcov.info`. Paths are normalized to start at `lib/`.
List<FileCoverage> parseLcov(String lcov) {
  final files = <FileCoverage>[];
  String? path;
  var found = 0;
  var hit = 0;
  for (final line in lcov.split('\n')) {
    if (line.startsWith('SF:')) {
      path = _fromLib(line.substring(3).trim());
      found = 0;
      hit = 0;
    } else if (line.startsWith('LF:')) {
      found = int.parse(line.substring(3).trim());
    } else if (line.startsWith('LH:')) {
      hit = int.parse(line.substring(3).trim());
    } else if (line.trim() == 'end_of_record' && path != null) {
      files.add(FileCoverage(path: path, linesFound: found, linesHit: hit));
      path = null;
    }
  }
  return files;
}

/// Checks [coverage] against [minPercent], ignoring paths that start with
/// any of [excluded]. [libFiles] is every Dart file under `lib/`.
CoverageReport evaluateCoverage({
  required List<FileCoverage> coverage,
  required List<String> libFiles,
  required List<String> excluded,
  required double minPercent,
}) {
  bool included(String path) => !excluded.any(path.startsWith);

  final counted = coverage.where((file) => included(file.path)).toList();
  final found = counted.fold(0, (sum, file) => sum + file.linesFound);
  final hit = counted.fold(0, (sum, file) => sum + file.linesHit);
  final covered = counted.map((file) => file.path).toSet();

  return CoverageReport(
    percent: found == 0 ? 100 : hit * 100 / found,
    untestedFiles:
        libFiles
            .map(_fromLib)
            .where((path) => included(path) && !covered.contains(path))
            .toList()
          ..sort(),
    minPercent: minPercent,
  );
}

String _fromLib(String path) {
  final normalized = path.replaceAll(r'\', '/');
  if (normalized.startsWith('lib/')) return normalized;
  final index = normalized.lastIndexOf('/lib/');
  return index == -1 ? normalized : normalized.substring(index + 1);
}
