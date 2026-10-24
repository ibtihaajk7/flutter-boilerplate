import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_events.dart'; // slim:analytics
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart'; // slim:analytics

/// Example controller: state, logic and analytics live here, widgets only
/// render it.
class CounterController extends ChangeNotifier {
  CounterController(
    this._analytics, // slim:analytics
  );

  final AnalyticsService _analytics; // slim:analytics
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
    // slim:analytics:start
    _analytics.track(AnalyticsEvents.counterIncremented, {
      AnalyticsParams.count: _count,
    }).ignore();
    // slim:analytics:end
  }

  void reset() {
    if (_count == 0) return;
    _count = 0;
    notifyListeners();
  }
}
