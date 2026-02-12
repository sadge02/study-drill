import 'package:study_drill/utils/constants/authentication/utils/authentication_validator_constants.dart';

class AuthenticationValidator {
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }
    if (username.length <
        AuthenticationValidatorConstants.minimumSizeUsername) {
      return 'Username is too short';
    }
    if (username.length >
        AuthenticationValidatorConstants.maximumSizeUsername) {
      return 'Username is too long (max ${AuthenticationValidatorConstants.maximumSizeUsername})';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    if (email.length > AuthenticationValidatorConstants.maximumSizeEmail) {
      return 'Email is too long (max ${AuthenticationValidatorConstants.maximumSizeEmail})';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length <
        AuthenticationValidatorConstants.minimumSizePassword) {
      return 'Password must be at least ${AuthenticationValidatorConstants.minimumSizePassword} characters';
    }
    if (password.length >
        AuthenticationValidatorConstants.maximumSizePassword) {
      return 'Password is too long (max ${AuthenticationValidatorConstants.maximumSizePassword})';
    }
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    if (!hasLetter || !hasDigit) {
      return 'Password must contain both letters and numbers';
    }
    return null;
  }
}
