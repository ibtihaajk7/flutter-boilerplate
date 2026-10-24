import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/theme/app_colors.dart';
import 'package:flutter_boilerplate/core/theme/app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = AppColors.scheme(brightness);
    return ThemeData(
      colorScheme: colorScheme,
      textTheme: AppTextStyles.textTheme().apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );
  }
}
