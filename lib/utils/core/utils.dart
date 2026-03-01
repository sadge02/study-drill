import 'package:flutter/cupertino.dart';
import 'package:study_drill/utils/constants/core/general_constants.dart';

import '../constants/authentication/validator/authentication_validator_constants.dart';

/// Utility class providing helper methods for common app operations.
///
/// Contains methods for responsive design checks, media query operations,
/// and input validation.
class Utils {
  /// Regex pattern for email validation (compiled once at startup).
  static final RegExp _emailRegex = RegExp(
    AuthenticationValidatorConstants.emailRegexPattern,
  );

  /// Gets the width of the device screen in logical pixels.
  ///
  /// Returns the current viewport width from MediaQuery.
  static double getWidth(BuildContext context) {
    return MediaQuery.widthOf(context);
  }

  /// Checks if the device is in mobile view mode.
  ///
  /// Returns true if screen width is below [GeneralConstants.mobileThreshold].
  /// Used for responsive layout decisions.
  static bool isMobile(BuildContext context) {
    return getWidth(context) < GeneralConstants.mobileThreshold;
  }

  /// Validates if the given string is a valid email address.
  ///
  /// Uses the same regex pattern as [AuthenticationValidator] for consistency.
  /// Pattern: `user@domain.extension`
  ///
  /// Returns true if the email format is valid, false otherwise.
  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email);
  }
}
