import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_events.dart';
import 'package:flutter_boilerplate/core/analytics/analytics_service.dart';

/// Example controller: state, logic and analytics live here, widgets only
/// render it.
class CounterController extends ChangeNotifier {
  CounterController({required this._analytics});

  final AnalyticsService _analytics;
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
    _analytics.track(AnalyticsEvents.counterIncremented, {
      AnalyticsParams.count: _count,
    }).ignore();
  }

  void reset() {
    if (_count == 0) return;
    _count = 0;
    notifyListeners();
  }
}
