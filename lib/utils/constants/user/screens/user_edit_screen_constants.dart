class UserEditScreenConstants {
  /// APP BAR ///

  static const String appBarTitle = 'Edit Profile';

  /// SECTION HEADERS ///

  static const String profileSection = 'Profile';

  static const String accountSection = 'Account';

  /// HINT TEXTS ///

  static const String usernameHint = 'Username';

  static const String descriptionHint = 'About you (Optional)';

  static const String profilePicHint = 'Profile Picture URL (Optional)';

  /// BUTTON LABELS ///

  static const String saveButtonLabel = 'Save Changes';

  /// SNACKBAR MESSAGES ///

  static const String updateSuccessMessage = 'Profile updated successfully.';

  /// VALIDATION ///

  static const String usernameEmptyError = 'Please enter a username';

  static const int usernameMinLength = 3;

  static const int usernameMaxLength = 32;

  static const String usernameTooShortError =
      'Username must be at least 3 characters';

  static const String usernameTooLongError =
      'Username must be at most 32 characters';

  static const int descriptionMaxLength = 300;

  static const String descriptionTooLongError =
      'Description must be at most 300 characters';

  /// SIZING ///

  static const double buttonWidth = 200.0;

  static const double buttonHeight = 50.0;

  static const double sectionSpacing = 24.0;

  static const double fieldSpacing = 14.0;

  static const double sectionHeaderFontSize = 16.0;

  static const double profilePicRadiusMobile = 48.0;

  static const double profilePicRadiusDesktop = 60.0;

  static const double profilePicBackgroundRadiusMobile = 52.0;

  static const double profilePicBackgroundRadiusDesktop = 64.0;

  static const double descriptionMaxLines = 4;

  /// AVATAR API ///

  static const String avatarApiBaseUrl = 'https://ui-avatars.com/api/';

  static const String avatarApiBackground = '27374D';

  static const String avatarApiForeground = 'fff';

  static const int avatarApiSize = 128;
}
