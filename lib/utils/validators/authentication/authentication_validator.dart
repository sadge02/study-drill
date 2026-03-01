import '../../constants/authentication/validator/authentication_validator_constants.dart';
import '../../constants/error/messages/firebase_exception_constants.dart';

/// Validator class for authentication-related input validation.
///
/// Provides static validation methods for username, email, and password fields.
/// All methods return null if validation passes, or an error message if validation fails.
class AuthenticationValidator {
  /// Regex pattern for email validation (compiled once at startup).
  static final RegExp _emailRegex = RegExp(
    AuthenticationValidatorConstants.emailRegexPattern,
  );

  /// Regex pattern for letter detection in password (compiled once at startup).
  static final RegExp _letterRegex = RegExp(
    AuthenticationValidatorConstants.letterRegexPattern,
  );

  /// Regex pattern for digit detection in password (compiled once at startup).
  static final RegExp _digitRegex = RegExp(
    AuthenticationValidatorConstants.digitRegexPattern,
  );

  /// Validates a username string.
  ///
  /// Checks for:
  /// - Non-null and non-empty
  /// - Minimum length: [AuthenticationValidatorConstants.minimumSizeUsername]
  /// - Maximum length: [AuthenticationValidatorConstants.maximumSizeUsername]
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return FirebaseExceptionConstants.usernameRequiredMessage;
    }
    if (username.length <
        AuthenticationValidatorConstants.minimumSizeUsername) {
      return FirebaseExceptionConstants.usernameShortMessage;
    }
    if (username.length >
        AuthenticationValidatorConstants.maximumSizeUsername) {
      return FirebaseExceptionConstants.usernameLongMessage;
    }
    return null;
  }

  /// Validates an email address string.
  ///
  /// Checks for:
  /// - Non-null and non-empty
  /// - Valid email format (user@domain.extension)
  /// - Maximum length: [AuthenticationValidatorConstants.maximumSizeEmail]
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return FirebaseExceptionConstants.emailRequiredMessage;
    }
    if (!_emailRegex.hasMatch(email)) {
      return FirebaseExceptionConstants.emailInvalidMessage;
    }
    if (email.length > AuthenticationValidatorConstants.maximumSizeEmail) {
      return FirebaseExceptionConstants.emailLongMessage;
    }
    return null;
  }

  /// Validates a password string.
  ///
  /// Checks for:
  /// - Non-null and non-empty
  /// - Minimum length: [AuthenticationValidatorConstants.minimumSizePassword]
  /// - Maximum length: [AuthenticationValidatorConstants.maximumSizePassword]
  /// - Contains at least one letter
  /// - Contains at least one digit
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return FirebaseExceptionConstants.passwordRequiredMessage;
    }
    if (password.length <
        AuthenticationValidatorConstants.minimumSizePassword) {
      return FirebaseExceptionConstants.passwordShortMessage;
    }
    if (password.length >
        AuthenticationValidatorConstants.maximumSizePassword) {
      return FirebaseExceptionConstants.passwordLongMessage;
    }
    final hasLetter = _letterRegex.hasMatch(password);
    final hasDigit = _digitRegex.hasMatch(password);
    if (!hasLetter || !hasDigit) {
      return FirebaseExceptionConstants.passwordComplexityMessage;
    }
    return null;
  }
}
