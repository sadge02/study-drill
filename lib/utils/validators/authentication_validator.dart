import 'package:study_drill/utils/constants/validator/authentication_validator_constants.dart';

class AuthenticationValidator {
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return AuthenticationValidatorConstants.usernameRequiredMessage;
    }
    if (username.length <
        AuthenticationValidatorConstants.minimumSizeUsername) {
      return AuthenticationValidatorConstants.usernameShortMessage;
    }
    if (username.length >
        AuthenticationValidatorConstants.maximumSizeUsername) {
      return AuthenticationValidatorConstants.usernameLongMessage;
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return AuthenticationValidatorConstants.emailRequiredMessage;
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(email)) {
      return AuthenticationValidatorConstants.emailInvalidMessage;
    }
    if (email.length > AuthenticationValidatorConstants.maximumSizeEmail) {
      return AuthenticationValidatorConstants.emailLongMessage;
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return AuthenticationValidatorConstants.passwordRequiredMessage;
    }
    if (password.length <
        AuthenticationValidatorConstants.minimumSizePassword) {
      return AuthenticationValidatorConstants.passwordShortMessage;
    }
    if (password.length >
        AuthenticationValidatorConstants.maximumSizePassword) {
      return AuthenticationValidatorConstants.passwordLongMessage;
    }
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    if (!hasLetter || !hasDigit) {
      return AuthenticationValidatorConstants.passwordComplexityMessage;
    }
    return null;
  }
}
