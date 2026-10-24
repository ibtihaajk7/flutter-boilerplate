// coverage:ignore-file
// Interface only: nothing to execute.

/// One analytics backend (Firebase, Mixpanel, your own API…).
///
/// The app never talks to a vendor SDK directly: it calls `AnalyticsService`,
/// which fans out to every registered provider. Adding or swapping a vendor
/// is one new class plus one line in `main.dart`. See
/// `docs/recipes/analytics-firebase.md` and `analytics-mixpanel.md`.
abstract interface class AnalyticsProvider {
  Future<void> init();

  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  Future<void> logScreenView(String screenName);

  /// `null` clears the user (sign-out).
  Future<void> setUserId(String? id);

  Future<void> setUserProperty(String name, String value);

  Future<void> setEnabled(bool enabled);
}
