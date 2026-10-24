import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/renamer.dart';

const _config = RenameConfig(
  name: 'my_app',
  org: 'com.acme',
  displayName: 'My App',
);

void main() {
  group('RenameConfig.validate', () {
    test('accepts a valid config', () {
      expect(_config.validate(), isEmpty);
    });

    test('rejects a name that is not snake_case', () {
      const config = RenameConfig(
        name: 'MyApp',
        org: 'com.acme',
        displayName: 'My App',
      );
      expect(config.validate(), hasLength(1));
    });

    test('rejects reserved words, bad orgs and bad display names', () {
      const config = RenameConfig(
        name: 'class',
        org: 'acme',
        displayName: 'Bob\'s "App"',
      );
      expect(config.validate(), hasLength(3));
    });
  });

  test('toCamelCase follows flutter create', () {
    expect(toCamelCase('my_cool_app'), 'myCoolApp');
    expect(toCamelCase('app'), 'app');
  });

  group('Renamer', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('renamer_test');
      _writeTemplate(root);
    });

    tearDown(() => root.deleteSync(recursive: true));

    String read(String path) => File('${root.path}/$path').readAsStringSync();

    test('renames package, ids and display name everywhere', () {
      Renamer(root).rename(_config);

      expect(read('pubspec.yaml'), contains('name: my_app\n'));
      expect(read('lib/app.dart'), contains('package:my_app/core.dart'));
      expect(
        read('android/app/build.gradle.kts'),
        contains('"com.acme.my_app"'),
      );
      expect(
        read('android/app/src/main/AndroidManifest.xml'),
        contains('android:label="My App"'),
      );
      expect(
        read('ios/Runner.xcodeproj/project.pbxproj'),
        contains('com.acme.myApp;'),
      );
      expect(
        read('ios/Runner/Info.plist'),
        contains('<string>My App</string>'),
      );
    });

    test('moves the Kotlin package and removes the old folders', () {
      Renamer(root).rename(_config);

      final kotlin = '${root.path}/android/app/src/main/kotlin';
      expect(
        File('$kotlin/com/acme/my_app/MainActivity.kt').readAsStringSync(),
        contains('package com.acme.my_app'),
      );
      expect(Directory('$kotlin/com/example').existsSync(), isFalse);
    });

    test('strips template-only blocks and deletes template-only files', () {
      Renamer(root).rename(_config);

      expect(read('README.md'), '# My App\n\nKeep me.\n');
      expect(File('${root.path}/tool/rename.dart').existsSync(), isFalse);
    });

    test('refuses to run twice', () {
      final renamer = Renamer(root)..rename(_config);

      expect(() => renamer.rename(_config), throwsStateError);
    });

    test('refuses an invalid config', () {
      const config = RenameConfig(name: 'x', org: 'acme', displayName: '');

      expect(() => Renamer(root).rename(config), throwsArgumentError);
    });
  });
}

void _writeTemplate(Directory root) {
  void write(String path, String content) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  write('pubspec.yaml', 'name: flutter_boilerplate\n');
  write('lib/app.dart', "import 'package:flutter_boilerplate/core.dart';\n");
  write(
    'android/app/build.gradle.kts',
    'applicationId = "com.example.flutter_boilerplate"\n',
  );
  write(
    'android/app/src/main/AndroidManifest.xml',
    '<application android:label="flutter_boilerplate">\n',
  );
  write(
    'android/app/src/main/kotlin/com/example/flutter_boilerplate/'
        'MainActivity.kt',
    'package com.example.flutter_boilerplate\n',
  );
  write(
    'ios/Runner.xcodeproj/project.pbxproj',
    'PRODUCT_BUNDLE_IDENTIFIER = com.example.flutterBoilerplate;\n',
  );
  write('ios/Runner/Info.plist', '<string>Flutter Boilerplate</string>\n');
  write(
    'README.md',
    '# Flutter Boilerplate\n\n'
        '<!-- template:start -->\nTemplate docs.\n<!-- template:end -->\n'
        'Keep me.\n',
  );
  write('tool/rename.dart', '// self-deleting\n');
}
