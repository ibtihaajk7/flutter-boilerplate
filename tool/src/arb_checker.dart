/// Problems in a set of ARB files, compared against the [template] file.
///
/// - every locale has exactly the template's keys
/// - every placeholder declared in the template appears in each translation
/// - no two template keys hold the same text (reuse the existing key)
List<String> findArbProblems(
  Map<String, Map<String, Object?>> arbsByFile, {
  required String template,
}) {
  final templateArb = arbsByFile[template];
  if (templateArb == null) {
    return ['Template $template not found'];
  }
  final templateKeys = _messageKeys(templateArb);
  final problems = <String>[];

  final keysByValue = <String, List<String>>{};
  for (final key in templateKeys) {
    keysByValue.putIfAbsent('${templateArb[key]}', () => []).add(key);
  }
  for (final MapEntry(key: value, value: keys) in keysByValue.entries) {
    if (keys.length > 1) {
      problems.add('$template: ${keys.join(', ')} share the text "$value"');
    }
  }

  for (final MapEntry(key: file, value: arb) in arbsByFile.entries) {
    if (file == template) continue;
    final keys = _messageKeys(arb);
    final missing = templateKeys.difference(keys);
    final extra = keys.difference(templateKeys);
    if (missing.isNotEmpty) {
      problems.add('$file: missing ${(missing.toList()..sort()).join(', ')}');
    }
    if (extra.isNotEmpty) {
      problems.add(
        '$file: not in $template: '
        '${(extra.toList()..sort()).join(', ')}',
      );
    }
    for (final key in templateKeys.intersection(keys)) {
      final message = '${arb[key]}';
      for (final placeholder in _placeholders(templateArb, key)) {
        if (!message.contains('{$placeholder')) {
          problems.add('$file: $key is missing placeholder {$placeholder}');
        }
      }
    }
  }
  return problems;
}

Set<String> _messageKeys(Map<String, Object?> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

Iterable<String> _placeholders(Map<String, Object?> arb, String key) {
  final metadata = arb['@$key'];
  if (metadata is! Map<String, Object?>) return const [];
  final placeholders = metadata['placeholders'];
  if (placeholders is! Map<String, Object?>) return const [];
  return placeholders.keys;
}
