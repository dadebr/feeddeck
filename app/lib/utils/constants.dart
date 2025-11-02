import 'package:flutter/material.dart';

/// [Constants] defines some constants for our app, to ensure a uniform style
/// across all widgets. we should reuse the constants defined here when ever
/// possible.
class Constants {
  static const brightness = Brightness.dark;
  // Elegant purple-blue color scheme
  static const primary = Color(0xff8b7aff); // Vibrant purple
  static const onPrimary = Color(0xff0f0f1e);
  static const secondary = Color(0xff3d3d5c); // Deep purple-gray
  static const onSecondary = Color(0xff9d8eff); // Light purple
  static const error = Color(0xffff6b6b); // Soft red
  static const onError = Color(0xffe8e8f0);
  static const surface = Color(0xff1a1a2e); // Deep navy blue
  static const onSurface = Color(0xffe8e8f0); // Soft white
  static const canvasColor = Color(0xff1a1a2e);
  static const appBarBackgroundColor = Colors.transparent;
  static const appBarElevation = 0.0;
  static const scrolledUnderElevation = 0.0;

  static const secondaryTextColor = Color(0xffa8a8c0); // Light gray-purple

  static const dividerColor = Color(0xff2d2d48); // Purple-tinted divider
  static const surfaceContainerBackgroundColor = Color(0xff12121f); // Darker navy

  static const breakpoint = 600.0;
  static const columnWidth = 352.0;
  static const columnSpacing = 4.0;
  static const centeredFormMaxWidth = 500.0;
  static const centeredFormLogoSize = 128.0;

  static const spacingExtraSmall = 4.0;
  static const spacingSmall = 8.0;
  static const spacingMiddle = 16.0;
  static const spacingLarge = 32.0;
  static const spacingExtraLarge = 64.0;

  static const elevatedButtonSize = 54.0;
}
