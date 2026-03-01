import 'package:flutter/material.dart';

class GeneralConstants {
  /// COLORS ///

  // Primary brand color used for main UI elements.
  static const Color primaryColor = Color(0xFF27374D);

  // Secondary brand color used for accents and secondary UI elements.
  static const Color secondaryColor = Color(0xFF0F4C75);

  // Tertiary brand color used for fills and backgrounds.
  static const Color tertiaryColor = Color(0xFF3282B8);

  // Background color for screens and main surfaces.
  static const Color backgroundColor = Colors.white;

  // Color used for success states and positive feedback.
  static const Color successColor = Colors.green;

  // Color used for failure states and error messages.
  static const Color failureColor = Colors.red;

  /// SPACINGS ///

  // Tiny spacing value (4dp) for minimal gaps.
  static const double tinySpacing = 4;

  // Small spacing value (12dp) for small gaps between elements.
  static const double smallSpacing = 12;

  // Medium spacing value (25dp) for moderate gaps between sections.
  static const double mediumSpacing = 25;

  // Large spacing value (50dp) for large gaps between major sections.
  static const double largeSpacing = 50;

  /// PADDINGS ///

  // Tiny padding (4dp) for minimal internal spacing.
  static const double tinyPadding = 4;

  // Small padding (12dp) for small internal spacing.
  static const double smallPadding = 12;

  // Medium padding (18dp) for moderate internal spacing.
  static const double mediumPadding = 18;

  // Large padding (24dp) for generous internal spacing.
  static const double largePadding = 24;

  // Huge padding (40dp) for maximum internal spacing.
  static const double hugePadding = 40;

  /// CIRCULAR RADII ///

  // Small corner radius (7.5dp) for subtle rounded corners.
  static const double smallCircularRadius = 7.5;

  // Medium corner radius (15dp) for standard rounded corners.
  static const double mediumCircularRadius = 15;

  // Large corner radius (20dp) for prominent rounded corners.
  static const double largeCircularRadius = 20;

  /// MARGINS ///

  // Small margin (12dp) for small external spacing.
  static const double smallMargin = 12;

  // Medium margin (18dp) for moderate external spacing.
  static const double mediumMargin = 18;

  // Large margin (36dp) for large external spacing.
  static const double largeMargin = 36;

  /// FONTS ///

  // Small font size (14dp) for body text and small labels.
  static const double smallFontSize = 14;

  // Medium font size (20dp) for regular text and medium labels.
  static const double mediumFontSize = 20;

  // Large font size (24dp) for large text and prominent labels.
  static const double largeFontSize = 24;

  /// TITLES ///

  // Small title size (24dp) for minor headings.
  static const double smallTitleSize = 24;

  // Medium title size (48dp) for section headings.
  static const double mediumTitleSize = 48;

  // Large title size (64dp) for major page headings.
  static const double largeTitleSize = 64;

  /// ICONS ///

  // Tiny icon size (14dp) for very small icons.
  static const double smallSmallIconSize = 14;

  // Small icon size (24dp) for standard small icons.
  static const double smallIconSize = 24;

  // Medium icon size (40dp) for medium icons.
  static const double mediumIconSize = 40;

  // Large icon size (80dp) for prominent large icons.
  static const double largeIconSize = 80;

  /// NOTIFICATIONS ///

  // Duration in milliseconds for notification display (3000ms = 3 seconds).
  static const int notificationDurationMs = 3000;

  // Elevation for notification/snackbar shadows.
  static const double notificationElevation = 0;

  /// BUTTONS ///

  // Elevation for button shadows.
  static const double buttonElevation = 0;

  /// ANIMATIONS ///

  // Duration in milliseconds for screen transitions (750ms).
  static const int transitionDurationMs = 750;

  // Starting position offset for slide animations (0.1 = 10% of screen width).
  static const double slideBegin = 0.1;

  /// APPBARS ///

  // Elevation for app bar shadows.
  static const double appBarElevation = 0;

  // Height of the app bar (100dp).
  static const double appBarHeight = 100;

  /// TEXT ///

  // Maximum number of lines for text overflow handling.
  static const int maxLines = 1;

  /// APPLICATION ///

  // Application name.
  static const String name = 'Study Drill';

  // Full application name with "App" suffix.
  static const String appName = '$name App';

  /// SCREEN ///

  // Threshold width (600dp) to distinguish between mobile and desktop.
  static const int mobileThreshold = 600;

  // Width ratio for mobile screens (0.9 = 90% of screen width).
  static const double widthRatioMobile = 0.9;

  // Width ratio for desktop screens (0.6 = 60% of screen width).
  static const double widthRatioDesktop = 0.6;

  /// OPACITY ///

  // Small opacity value (0.75) for subtle fading.
  static const double smallOpacity = 0.75;

  // Medium opacity value (0.5) for moderate fading.
  static const double mediumOpacity = 0.5;

  // Large opacity value (0.25) for strong fading.
  static const double largeOpacity = 0.25;
}
