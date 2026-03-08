import '../../authentication/validator/authentication_validator_constants.dart';

class FirebaseExceptionConstants {
  /// GENERAL MESSAGES ///

  // Error message for required field validation failure.
  static const String requiredFieldMessage = 'This field is required.';

  // Error message for unexpected/unknown errors.
  static const String unexpectedErrorMessage =
      'An unexpected error occurred. Please try again.';

  // Error message when authentication process fails.
  static const String authenticationFailedMessage =
      'Authentication failed. Please check your credentials and try again.';

  // Error message for invalid email or password combination.
  static const String invalidCredentialsMessage =
      'Invalid email or password. Please try again.';

  /// EMAIL MESSAGES ///

  // Validation error for empty email field.
  static const String emailRequiredMessage = 'Email is required.';

  // Validation error for invalid email format.
  static const String emailInvalidMessage =
      'Please enter a valid email address.';

  // Validation error for email exceeding maximum length.
  static const String emailLongMessage =
      'Email must be under ${AuthenticationValidatorConstants.maximumSizeEmail} characters.';

  // Error message when email is already registered.
  static const String emailAlreadyInUseMessage =
      'The email address is already in use.';

  // Error message when too many login attempts made.
  static const String tooManyRequestsMessage =
      'Too many attempts. Please try again later.';

  // Error message for network connectivity issues.
  static const String networkRequestFailed =
      'Network error. Please check your internet connection.';

  /// USERNAME MESSAGES ///

  // Validation error for empty username field.
  static const String usernameRequiredMessage = 'Username is required.';

  // Error message when username is already taken.
  static const String usernameTakenMessage = 'This username is already taken.';

  // Validation error for username below minimum length.
  static const String usernameShortMessage =
      'Username must be at least ${AuthenticationValidatorConstants.minimumSizeUsername} characters.';

  // Validation error for username exceeding maximum length.
  static const String usernameLongMessage =
      'Username must be under ${AuthenticationValidatorConstants.maximumSizeUsername} characters.';

  /// USER MESSAGES ///

  // Error message when user account not found.
  static const String userNotFoundMessage =
      'No user found with the provided email.';

  // Error message when user action requires being logged in.
  static const String userNotLoggedInMessage = 'You must be logged in.';

  // Error message when user is already a member of a group.
  static const String userAlreadyAMemberMessage = 'Already a member.';

  // Error message when join request already sent to group.
  static const String userAlreadyRequestedMessage = 'Request already sent.';

  // Success message when join request sent successfully.
  static const String userJoinRequestMessage = 'Join request sent.';

  // Success message when user joins group successfully.
  static const String userSuccessfullyJoinedMessage =
      'Successfully joined the group.';

  // Success message when user leaves group successfully.
  static const String userSuccessfullyLeftMessage =
      'Successfully left the group.';

  // Error message when user fails to join group.
  static const String userUnsuccessfullyJoinedMessage =
      'Failed to join the group.';

  // Error message when user fails to leave group.
  static const String userUnsuccessfullyLeftMessage =
      'Failed to leave the group.';

  // Error message when user account is disabled/banned.
  static const String userDisabledMessage =
      'This user account has been disabled.';

  // Error message when user cannot delete account due to group ownership.
  static const String userDeleteAccountConditionsMessage =
      'Cannot delete account. You are the owner of some group. Please delete these group or transfer ownership first.';

  /// PASSWORD MESSAGES ///

  // Validation error for empty password field.
  static const String passwordRequiredMessage = 'Paswword is required.';

  // Validation error for password below minimum length.
  static const String passwordShortMessage =
      'Password must be at least ${AuthenticationValidatorConstants.minimumSizePassword} characters.';

  // Validation error for password exceeding maximum length.
  static const String passwordLongMessage =
      'Password must be under ${AuthenticationValidatorConstants.maximumSizePassword} characters.';

  // Validation error for password missing letters or numbers.
  static const String passwordComplexityMessage =
      'Password must contain both letters and numbers.';

  // Error message when provided password is incorrect.
  static const String passwordWrongMessage = 'The password is incorrect.';

  // Error message when password is too weak for security requirements.
  static const String passwordWeakMessage =
      'The provided password is too weak.';

  static const String passwordMismatchMessage =
      'The new password and confirmation do not match.';

  /// GROUP MESSAGES ///

  // Error message when group creation fails.
  static const String groupCreateFailedMessage = 'Failed to create group.';

  // Error message when group does not exist.
  static const String groupDoesNotExist = 'Group does not exist.';

  // Error message when group owner attempts to leave without transferring ownership.
  static const String groupOwnerLeaveMessage =
      'You are the owner of this group. Please transfer ownership or delete the group before leaving.';

  // Success message when user leaves group.
  static const String groupLeaveSuccessMessage = 'You have left the group.';

  // Error message when user fails to leave group.
  static const String groupLeaveFailedMessage = 'Failed to leave the group.';

  // Success message when group ownership transferred.
  static const String groupTransferOwnershipSuccessMessage =
      'Group ownership transferred successfully.';

  // Error message when group ownership transfer fails.
  static const String groupTransferOwnershipFailedMessage =
      'Failed to transfer group ownership.';

  // Error message when non-owner attempts to transfer group ownership.
  static const String groupNonAuthorTransferOwnershipMessage =
      'Only the group owner can transfer ownership.';

  // Error message when new group owner is not a group member.
  static const String groupNewOwnerMustBeMemberMessage =
      'The new owner must be a member of the group.';

  // Error message when non-owner attempts to delete group.
  static const String groupNonOwnerDeleteMessage =
      'Only the group owner can delete the group.';

  // Success message when group is deleted.
  static const String groupDeleteSuccessMessage = 'Group deleted successfully.';

  // Error message when group deletion fails.
  static const String groupDeleteFailedMessage = 'Failed to delete the group.';

  // Error message when user lacks permission to update group.
  static const String groupUpdateNotAuthorMessage =
      'You don\'t have permission to update this group.';

  // Success message when group is updated.
  static const String groupUpdateSuccessMessage = 'Group updated successfully.';

  // Error message when group update fails.
  static const String groupUpdateFailedMessage = 'Failed to update the group.';

  /// FIREBASE EXCEPTIONS ///

  // Firebase exception code for weak password.
  static const String weakPasswordException = 'weak-password';

  // Firebase exception code for email already in use.
  static const String emailAlreadyInUseException = 'email-already-in-use';

  // Firebase exception code for user not found.
  static const String userNotFoundException = 'user-not-found';

  // Firebase exception code for wrong password.
  static const String wrongPasswordException = 'wrong-password';

  // Firebase exception code for invalid credentials.
  static const String invalidCredentialException = 'invalid-credential';

  // Firebase exception code for invalid email format.
  static const String invalidEmailException = 'invalid-email';

  // Firebase exception code for disabled user account.
  static const String userDisabledException = 'user-disabled';

  // Firebase exception code for too many requests.
  static const String tooManyRequestsException = 'too-many-requests';

  // Firebase exception code for network request failure.
  static const String networkRequestFailedException = 'network-request-failed';

  // Pending request
  static const String userNotInPendingListMessage =
      'This user does not have a pending join request.';

  // Approve
  static const String groupJoinRequestApprovedMessage =
      'Join request approved. The user has been added to the group.';
  static const String groupJoinRequestApprovalFailedMessage =
      'Failed to approve join request. Please try again.';

  // Reject
  static const String groupJoinRequestRejectedMessage =
      'Join request rejected.';
  static const String groupJoinRequestRejectionFailedMessage =
      'Failed to reject join request. Please try again.';

  // Kick
  static const String groupCannotKickOwnerMessage =
      'The group owner cannot be removed from the group.';
  static const String groupKickMemberSuccessMessage =
      'The member has been removed from the group.';
  static const String groupKickMemberFailedMessage =
      'Failed to remove member. Please try again.';

  // Role management
  static const String groupOnlyAuthorCanManageAdminsMessage =
      'Only the group owner can promote or demote admins.';
  static const String groupRoleChangeFailedMessage =
      'Failed to update member role. Please try again.';
  static const String groupUserNotAMemberMessage =
      'The user is not a member of this group.';

  /// USER SERVICE MESSAGES ///

  static const String userUpdateFailedMessage =
      'Failed to update user profile. Please try again.';

  static const String userDeleteFailedMessage =
      'Failed to delete user account. Please try again.';

  static const String userAlreadyFriendsMessage = 'You are already friends.';

  static const String userFriendRequestFailedMessage =
      'Failed to send friend request. Please try again.';

  static const String userNotFriendsMessage = 'You are not friends.';

  static const String userRemoveFriendFailedMessage =
      'Failed to remove friend. Please try again.';
}
