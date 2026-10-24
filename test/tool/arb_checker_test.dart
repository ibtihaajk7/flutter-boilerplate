import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/arb_checker.dart';

void main() {
  const en = <String, Object?>{
    'hello': 'Hello {name}',
    '@hello': {
      'placeholders': {
        'name': {'type': 'String'},
      },
    },
    'bye': 'Bye',
  };

  test('in-sync files have no problems', () {
    final problems = findArbProblems({
      'app_en.arb': en,
      'app_fr.arb': {'hello': 'Salut {name}', 'bye': 'Salut'},
    }, template: 'app_en.arb');

    expect(problems, isEmpty);
  });

  test('reports missing and extra keys', () {
    final problems = findArbProblems({
      'app_en.arb': en,
      'app_fr.arb': {'hello': 'Salut {name}', 'extra': 'x'},
    }, template: 'app_en.arb');

    expect(problems, [
      'app_fr.arb: missing bye',
      'app_fr.arb: not in app_en.arb: extra',
    ]);
  });

  test('reports a translation that lost its placeholder', () {
    final problems = findArbProblems({
      'app_en.arb': en,
      'app_fr.arb': {'hello': 'Salut', 'bye': 'Salut'},
    }, template: 'app_en.arb');

    expect(problems, ['app_fr.arb: hello is missing placeholder {name}']);
  });

  test('reports duplicate English copy', () {
    final problems = findArbProblems({
      'app_en.arb': {'ok': 'OK', 'confirm': 'OK'},
    }, template: 'app_en.arb');

    expect(problems, ['app_en.arb: ok, confirm share the text "OK"']);
  });

  test('reports a missing template', () {
    expect(findArbProblems({}, template: 'app_en.arb'), hasLength(1));
  });
}
