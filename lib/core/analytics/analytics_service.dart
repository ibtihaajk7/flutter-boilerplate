import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_events.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_provider.dart';

/// The only analytics entry point the app uses.
///
/// Fans every call out to all [AnalyticsProvider]s. A failing provider is
/// logged and skipped: analytics must never crash the app or block another
/// provider.
class AnalyticsService {
  AnalyticsService(this._providers, {this._enabled = true});

  final List<AnalyticsProvider> _providers;
  bool _enabled;

  bool get isEnabled => _enabled;

  Future<void> init() => _forEach('init', (provider) => provider.init());

  /// Turns collection on or off everywhere, e.g. from a privacy setting.
  Future<void> setEnabled(bool enabled) {
    _enabled = enabled;
    return _forEach('setEnabled', (provider) => provider.setEnabled(enabled));
  }

  Future<void> track(String event, [Map<String, Object>? parameters]) {
    assert(isValidAnalyticsName(event), 'Invalid event name "$event"');
    assert(
      parameters?.keys.every(isValidAnalyticsName) ?? true,
      'Invalid parameter name in $parameters',
    );
    if (!_enabled) return Future.value();
    return _forEach(
      'track:$event',
      (provider) => provider.logEvent(event, parameters: parameters),
    );
  }

  Future<void> logScreenView(String screenName) {
    if (!_enabled) return Future.value();
    return _forEach(
      'logScreenView:$screenName',
      (provider) => provider.logScreenView(screenName),
    );
  }

  Future<void> setUserId(String? id) {
    if (!_enabled) return Future.value();
    return _forEach('setUserId', (provider) => provider.setUserId(id));
  }

  Future<void> setUserProperty(String name, String value) {
    assert(isValidAnalyticsName(name), 'Invalid user property "$name"');
    if (!_enabled) return Future.value();
    return _forEach(
      'setUserProperty:$name',
      (provider) => provider.setUserProperty(name, value),
    );
  }

  Future<void> _forEach(
    String action,
    Future<void> Function(AnalyticsProvider provider) call,
  ) async {
    for (final provider in _providers) {
      try {
        await call(provider);
      } on Object catch (error) {
        debugPrint('Analytics ${provider.runtimeType} $action failed: $error');
      }
    }
  }
}
