import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to values in `.env` (copied from `.env.example` by
/// `make setup`). Never read `dotenv.env` directly outside this class.
abstract final class AppEnv {
  static Future<void> load() => dotenv.load(isOptional: true);

  static String get apiBaseUrl => dotenv.maybeGet('API_BASE_URL') ?? '';
}
