import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/slimmer.dart';

void main() {
  group('applySlimMarkers', () {
    const dart = '''
a();
b(); // slim:analytics
// slim:crash:start
c();
// slim:crash:end
d();''';

    test('removes marked lines and blocks of removed features', () {
      expect(applySlimMarkers(dart, removed: {'analytics', 'crash'}), '''
a();
d();''');
    });

    test('keeps kept features, markers included', () {
      expect(applySlimMarkers(dart, removed: {'analytics'}), '''
a();
// slim:crash:start
c();
// slim:crash:end
d();''');
    });

    test('strip-markers keeps the code but drops the markers', () {
      expect(applySlimMarkers(dart, removed: {}, stripMarkers: true), '''
a();
b();
c();
d();''');
    });

    test('understands XML and hash comments', () {
      const xml = '''
<a/>
<b/> <!-- slim:notifications -->
<!-- slim:notifications:start -->
<c/>
<!-- slim:notifications:end -->
key: value # slim:notifications''';

      expect(applySlimMarkers(xml, removed: {'notifications'}), '<a/>');
    });

    test('nested blocks: an outer removal removes the inner block', () {
      const nested = '''
// slim:crash:start
x();
// slim:analytics:start
y();
// slim:analytics:end
// slim:crash:end
z();''';

      expect(applySlimMarkers(nested, removed: {'crash'}), 'z();');
      expect(applySlimMarkers(nested, removed: {'analytics'}), '''
// slim:crash:start
x();
// slim:crash:end
z();''');
    });

    test('rejects unbalanced blocks', () {
      expect(
        () => applySlimMarkers('// slim:crash:start\nx();', removed: {}),
        throwsFormatException,
      );
      expect(
        () => applySlimMarkers('// slim:crash:end', removed: {}),
        throwsFormatException,
      );
      expect(
        () => applySlimMarkers(
          '// slim:crash:start\n// slim:analytics:end',
          removed: {},
        ),
        throwsFormatException,
      );
    });
  });

  test('removeArbKeys drops keys and their metadata, keeping order', () {
    const arb =
        '{"b": "B", "a": "A {n}", "@a": {"placeholders": {}}, "c": "C"}';

    expect(removeArbKeys(arb, ['a']), '{\n  "b": "B",\n  "c": "C"\n}\n');
  });

  group('SlimFeature.parse', () {
    test('reads a comma-separated list', () {
      expect(SlimFeature.parse('analytics, crash,'), {
        SlimFeature.analytics,
        SlimFeature.crash,
      });
    });

    test('rejects unknown modules', () {
      expect(() => SlimFeature.parse('payments'), throwsFormatException);
    });
  });

  group('slim', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('slimmer_test');
      void write(String path, String content) => File('${root.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(content);

      write('lib/core/notifications/service.dart', 'class S {}\n');
      write('lib/features/home/notification_card.dart', 'class C {}\n');
      write('lib/main.dart', 'a();\nb(); // slim:notifications\n');
      write('lib/l10n/app_en.arb', '{"title": "T", "notificationsTitle": "N"}');
      write('tool/src/slimmer.dart', 'x(); // slim:notifications\n');
    });

    tearDown(() => root.deleteSync(recursive: true));

    String read(String path) => File('${root.path}/$path').readAsStringSync();

    test('deletes the feature files, marked code and strings', () {
      final changed = slim(root, {SlimFeature.notifications});

      expect(changed, [
        'lib/core/notifications',
        'lib/features/home/notification_card.dart',
        'lib/l10n/app_en.arb',
        'lib/main.dart',
      ]);
      expect(
        Directory('${root.path}/lib/core/notifications').existsSync(),
        isFalse,
      );
      expect(read('lib/main.dart'), 'a();\n');
      expect(read('lib/l10n/app_en.arb'), '{\n  "title": "T"\n}\n');
    });

    test('never rewrites the tool itself', () {
      slim(root, {SlimFeature.notifications});

      expect(read('tool/src/slimmer.dart'), contains('slim:notifications'));
    });

    test('with nothing to remove, only strips markers when asked', () {
      expect(slim(root, {}), isEmpty);
      expect(slim(root, {}, stripMarkers: true), ['lib/main.dart']);
      expect(read('lib/main.dart'), 'a();\nb();\n');
    });
  });
}
