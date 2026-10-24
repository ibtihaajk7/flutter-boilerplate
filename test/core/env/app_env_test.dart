import 'package:flutter_boilerplate/core/env/app_env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load succeeds even when .env is missing or empty', () async {
    await expectLater(AppEnv.load(), completes);
  });

  test('reads API_BASE_URL', () {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.test');

    expect(AppEnv.apiBaseUrl, 'https://api.test');
  });

  test('missing values fall back to empty strings', () {
    dotenv.loadFromString(isOptional: true);

    expect(AppEnv.apiBaseUrl, isEmpty);
  });
}
