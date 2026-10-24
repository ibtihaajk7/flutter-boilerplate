/// Layout classes. Pick layouts from the space a widget actually gets
/// (`LayoutBuilder`), not from the device type.
enum ScreenType {
  phone,
  tablet;

  /// Width, in logical pixels, from which a layout counts as tablet.
  static const double tabletMinWidth = 600;

  static ScreenType fromWidth(double width) =>
      width >= tabletMinWidth ? ScreenType.tablet : ScreenType.phone;
}
