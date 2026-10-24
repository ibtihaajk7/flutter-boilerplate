/// Every event and parameter name the app sends, in one place.
///
/// Names are `snake_case`, start with a letter and are at most 40 characters,
/// which every major vendor accepts. `AnalyticsService` asserts this in debug.
abstract final class AnalyticsEvents {
  static const String buttonTap = 'button_tap';
  static const String counterIncremented = 'counter_incremented';
}

abstract final class AnalyticsParams {
  static const String buttonName = 'button_name';
  static const String count = 'count';
}

final _validName = RegExp(r'^[a-z][a-z0-9_]{0,39}$');

/// Whether [name] is safe to send as an event or parameter name.
bool isValidAnalyticsName(String name) => _validName.hasMatch(name);
