import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart';

/// Logs a screen view for every named route the app shows.
///
/// Give routes a name (`RouteSettings(name: 'settings')`) to have them
/// tracked; unnamed routes (dialogs, sheets) are ignored.
class AnalyticsRouteObserver extends RouteObserver<ModalRoute<Object?>> {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _logScreen(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _logScreen(previousRoute);
  }

  void _logScreen(Route<dynamic> route) {
    final name = route.settings.name;
    if (route is PageRoute && name != null) {
      _analytics.logScreenView(name).ignore();
    }
  }
}
