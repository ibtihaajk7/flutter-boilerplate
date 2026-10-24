import 'package:flutter/foundation.dart';

/// Example controller: state, logic and analytics live here, widgets only
/// render it.
class CounterController extends ChangeNotifier {
  CounterController();

  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void reset() {
    if (_count == 0) return;
    _count = 0;
    notifyListeners();
  }
}
