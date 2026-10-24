import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/scale/app_scale.dart';

/// Text sizes from the design file, scaled with SafeScale.
///
/// Built on demand (not `static final`) so sizes follow the current screen:
/// a static field is computed once and would freeze on rotation or resize.
abstract final class AppTextStyles {
  static TextTheme textTheme() => TextTheme(
    displaySmall: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16.sp),
    bodyMedium: TextStyle(fontSize: 14.sp),
    bodySmall: TextStyle(fontSize: 12.sp),
    labelLarge: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
  );
}
