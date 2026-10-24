import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_provider.dart';

/// Prints every analytics call to the console. The default provider, so a
/// fresh project has working analytics calls before any vendor is set up.
class DebugAnalyticsProvider implements AnalyticsProvider {
  DebugAnalyticsProvider({void Function(String message)? log})
    : _log = log ?? debugPrint;

  final void Function(String message) _log;

  @override
  Future<void> init() async => _log('[analytics] init');

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async =>
      _log('[analytics] $name ${parameters ?? const {}}');

  @override
  Future<void> logScreenView(String screenName) async =>
      _log('[analytics] screen $screenName');

  @override
  Future<void> setUserId(String? id) async => _log('[analytics] user $id');

  @override
  Future<void> setUserProperty(String name, String value) async =>
      _log('[analytics] property $name=$value');

  @override
  Future<void> setEnabled(bool enabled) async =>
      _log('[analytics] enabled $enabled');
}
