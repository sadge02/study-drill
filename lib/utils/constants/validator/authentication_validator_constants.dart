class AuthenticationValidatorConstants {
  /// LENGTH ///
  static const int minimumSizeUsername = 1;
  static const int maximumSizeUsername = 64;

  static const int maximumSizeEmail = 64;

  static const int minimumSizePassword = 8;
  static const int maximumSizePassword = 32;

  /// MESSAGES ///
  static const String requiredFieldMessage = 'This field is required.';
  static const String requiredEmailMessage = 'Email is required.';
  static const String requiredUsernameMessage = 'Username is required.';
  static const String requiredPasswordMessage = 'Password is required.';

  static const String invalidEmailMessage =
      'Please enter a valid email address.';

  static const String usernameShortMessage =
      'Username must be at least ${AuthenticationValidatorConstants.minimumSizeUsername} character';
  static const String passwordShortMessage =
      'Password must be at least ${AuthenticationValidatorConstants.minimumSizePassword} characters';

  static const String usernameLongMessage =
      'Username is too long (max ${AuthenticationValidatorConstants.maximumSizeUsername})';
  static const String emailLongMessage =
      'Email is too long (max ${AuthenticationValidatorConstants.maximumSizeEmail})';
  static const String passwordLongMessage =
      'Password is too long (max ${AuthenticationValidatorConstants.maximumSizePassword})';

  static const String passwordMismatchMessage = 'Passwords do not match.';

  static const String passwordComplexityMessage =
      'Password must contain both letters and numbers.';
}
