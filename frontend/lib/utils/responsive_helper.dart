import 'package:flutter/material.dart';

/// Helper class for responsive design
/// Provides methods to calculate responsive sizes based on screen dimensions
class ResponsiveHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double textScaleFactor;

  /// Initialize responsive helper with context
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    textScaleFactor = _mediaQueryData.textScaleFactor;
  }

  /// Get responsive width (percentage of screen width)
  static double getWidth(double percentage) {
    return blockSizeHorizontal * percentage;
  }

  /// Get responsive height (percentage of screen height)
  static double getHeight(double percentage) {
    return blockSizeVertical * percentage;
  }

  /// Get responsive font size
  static double getResponsiveFontSize(double baseFontSize) {
    return baseFontSize * textScaleFactor;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding({
    double horizontal = 16,
    double vertical = 16,
  }) {
    return EdgeInsets.symmetric(
      horizontal: getWidth(horizontal / 10),
      vertical: getHeight(vertical / 10),
    );
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is mobile (width < 600)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if device is tablet (width >= 600)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  /// Get responsive border radius
  static BorderRadius getResponsiveBorderRadius(double baseRadius) {
    return BorderRadius.circular(baseRadius);
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(double baseSize) {
    if (screenWidth < 360) return baseSize * 0.8;
    if (screenWidth > 800) return baseSize * 1.2;
    return baseSize;
  }
}
