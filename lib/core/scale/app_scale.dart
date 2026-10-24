import 'package:flutter/widgets.dart';
import 'package:safe_scale/safe_scale.dart';

/// The frame the designs are drawn against (iPhone 13/14/15 in Figma).
///
/// Every size you copy from a design file is relative to this frame.
abstract final class DesignFrame {
  static const double width = 390;
  static const double height = 844;
}

/// Width-based UI scale for [SafeScale].
///
/// We scale by `width / DesignFrame.width`, then clamp so the UI does not
/// blow up on older / budget phones (e.g. iPhone 7 Plus, HD+ Android): those
/// have a relatively large logical width but a lower `devicePixelRatio`, so
/// without a tighter cap everything feels oversized. Tablets get a little
/// extra room, everything else stays close to the design.
double computeSafeScale({
  required double width,
  required double devicePixelRatio,
}) {
  // Heuristic: "big logical phone, not @3x sharp". Tune here if a device
  // class mis-fires.
  final isLowDensityLargeScreen = width > 360 && devicePixelRatio < 3.0;
  final isTablet = width > 600;

  final scale = width / DesignFrame.width;
  // Tablets first: iPads and most Android tablets are @2x, so the
  // low-density check below would otherwise catch them too.
  if (isTablet) {
    return scale.clamp(1.0, 1.2);
  }
  if (isLowDensityLargeScreen) {
    return scale.clamp(0.85, 1.0);
  }
  return scale.clamp(0.9, 1.1);
}

/// Initializes [SafeScale] for the current screen. Call once at the top of
/// the root widget's `build`, before anything reads a scaled size.
void initSafeScale(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  SafeScale().init(
    context,
    DesignFrame.height,
    DesignFrame.width,
    scale: computeSafeScale(width: width, devicePixelRatio: devicePixelRatio),
  );
}

/// Design-file sizes to device sizes, e.g. `16.sp`, `24.w`, `48.h`.
extension SafeScaleNum on num {
  /// Font size from the design file.
  double get sp => SafeScale.getMyDynamicFontSize(toDouble());

  /// Horizontal size (widths, horizontal padding) from the design file.
  double get w => SafeScale.getMyDynamicWidth(toDouble());

  /// Vertical size (heights, vertical padding) from the design file.
  double get h => SafeScale.getMyDynamicHeight(toDouble());
}
