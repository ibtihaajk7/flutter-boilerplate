import 'package:flutter_boilerplate/core/scale/app_scale.dart';

/// Spacing scale. Use these with `Row(spacing:)` / `Column(spacing:)` and
/// `EdgeInsets` instead of ad hoc numbers.
abstract final class AppSpacing {
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
}
