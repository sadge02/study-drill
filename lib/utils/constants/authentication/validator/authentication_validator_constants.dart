class AuthenticationValidatorConstants {
  /// LENGTH ///

  // Minimum length for username field.
  static const int minimumSizeUsername = 3;

  // Maximum length for username field.
  static const int maximumSizeUsername = 32;

  // Maximum length for email field.
  static const int maximumSizeEmail = 64;

  // Minimum length for password field.
  static const int minimumSizePassword = 8;

  // Maximum length for password field.
  static const int maximumSizePassword = 32;

  /// REGEX PATTERNS ///

  // Regex pattern for email validation: user@domain.extension
  static const String emailRegexPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  // Regex pattern for letter detection in password validation (A-Z, a-z).
  static const String letterRegexPattern = r'[a-zA-Z]';

  // Regex pattern for digit detection in password validation (0-9).
  static const String digitRegexPattern = r'[0-9]';
}
