import 'package:flutter/material.dart';

/// The only place raw colors live. Widgets read colors from
/// `Theme.of(context).colorScheme`, never from here directly.
abstract final class AppColors {
  static const Color seed = Color(0xFF3F51B5);

  static ColorScheme scheme(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
}
