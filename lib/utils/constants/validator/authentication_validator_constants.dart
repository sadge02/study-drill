class AuthenticationValidatorConstants {
  /// LENGTH ///
  static const int minimumSizeUsername = 3;
  static const int maximumSizeUsername = 25;

  static const int maximumSizeEmail = 64;

  static const int minimumSizePassword = 8;
  static const int maximumSizePassword = 32;

  /// GENERAL MESSAGES ///
  static const String requiredFieldMessage = 'This field is required.';
  static const String unexpectedErrorMessage =
      'An unexpected error occurred. Please try again.';
  static const String authenticationFailedMessage =
      'Authentication failed. Please check your credentials and try again.';
  static const String invalidCredentialsMessage =
      'Invalid email or password. Please try again.';

  /// EMAIL MESSAGES ///
  static const String emailRequiredMessage = 'Email is required.';
  static const String emailInvalidMessage =
      'Please enter a valid email address.';
  static const String emailLongMessage =
      'Email must be under ${AuthenticationValidatorConstants.maximumSizeEmail} characters.';
  static const String emailAlreadyInUseMessage =
      'The email address is already in use.';
  static const String tooManyRequestsMessage =
      'Too many attempts. Please try again later.';
  static const String networkRequestFailed =
      'Network error. Please check your internet connection.';

  /// USERNAME MESSAGES ///
  static const String usernameRequiredMessage = 'Username is required.';
  static const String usernameTakenMessage = 'This username is already taken.';
  static const String usernameShortMessage =
      'Username must be at least ${AuthenticationValidatorConstants.minimumSizeUsername} characters.';
  static const String usernameLongMessage =
      'Username must be under ${AuthenticationValidatorConstants.maximumSizeUsername} characters.';

  /// USER MESSAGES ///
  static const String userNotFoundMessage =
      'No user found with the provided email.';
  static const String userNotLoggedInMessage = 'You must be logged in.';
  static const String userAlreadyAMemberMessage = 'Already a member.';
  static const String userAlreadyRequestedMessage = 'Request already sent.';
  static const String userJoinRequestMessage = 'Join request sent.';
  static const String userSuccessfullyJoinedMessage =
      'Successfully joined the group.';
  static const String userSuccessfullyLeftMessage =
      'Successfully left the group.';
  static const String userUnsuccessfullyJoinedMessage =
      'Failed to join the group.';
  static const String userUnsuccessfullyLeftMessage =
      'Failed to leave the group.';
  static const String userDisabledMessage =
      'This user account has been disabled.';
  static const String userDeleteAccountConditionsMessage =
      'Cannot delete account. You are the owner of some groups. Please delete these groups or transfer ownership first.';

  /// PASSWORD MESSAGES ///
  static const String passwordRequiredMessage = 'Paswword is required.';
  static const String passwordShortMessage =
      'Password must be at least ${AuthenticationValidatorConstants.minimumSizePassword} characters.';
  static const String passwordLongMessage =
      'Password must be under ${AuthenticationValidatorConstants.maximumSizePassword} characters.';
  static const String passwordComplexityMessage =
      'Password must contain both letters and numbers.';
  static const String passwordWrongMessage = 'The password is incorrect.';
  static const String passwordMismatchMessage = 'Passwords do not match.';
  static const String passwordWeakMessage =
      'The provided password is too weak.';

  /// GROUP MESSAGES ///
  static const String groupCreateFailedMessage = 'Failed to create group.';
  static const String groupDoesNotExist = 'Group does not exist.';
  static const String groupOwnerLeaveMessage =
      'You are the owner of this group. Please transfer ownership or delete the group before leaving.';
  static const String groupLeaveSuccessMessage = 'You have left the group.';
  static const String groupLeaveFailedMessage = 'Failed to leave the group.';
  static const String groupTransferOwnershipSuccessMessage =
      'Group ownership transferred successfully.';
  static const String groupTransferOwnershipFailedMessage =
      'Failed to transfer group ownership.';
  static const String groupNonAuthorTransferOwnershipMessage =
      'Only the group owner can transfer ownership.';
  static const String groupNewOwnerMustBeMemberMessage =
      'The new owner must be a member of the group.';

  static const String groupNonOwnerDeleteMessage =
      'Only the group owner can delete the group.';
  static const String groupDeleteSuccessMessage = 'Group deleted successfully.';
  static const String groupDeleteFailedMessage = 'Failed to delete the group.';
  static const String groupUpdateNotAuthorMessage =
      'You don\'t have permission to update this group.';
  static const String groupUpdateSuccessMessage = 'Group updated successfully.';
  static const String groupUpdateFailedMessage = 'Failed to update the group.';

  /// FIREBASE EXCEPTIONS ///
  static const String weakPasswordException = 'weak-password';
  static const String emailAlreadyInUseException = 'email-already-in-use';
  static const String userNotFoundException = 'user-not-found';
  static const String wrongPasswordException = 'wrong-password';
  static const String invalidCredentialException = 'invalid-credential';
  static const String invalidEmailException = 'invalid-email';
  static const String userDisabledException = 'user-disabled';
  static const String tooManyRequestsException = 'too-many-requests';
  static const String networkRequestFailedException = 'network-request-failed';
}
