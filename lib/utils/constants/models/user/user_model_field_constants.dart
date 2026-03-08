class UserModelFieldConstants {
  /// USER MODEL FIELDS ///

  // User unique identifier field name.
  static const String id = 'id';

  // User email address field name.
  static const String email = 'email';

  // User display name field name.
  static const String username = 'username';

  // User lowercase username for case-insensitive search field name.
  static const String usernameLowercase = 'username_lowercase';

  // User bio/description field name.
  static const String summary = 'summary';

  // User profile picture URL field name.
  static const String profilePic = 'profile_pic';

  // User account creation date field name.
  static const String createdAt = 'created_at';

  // User account last update date field name.
  static const String updatedAt = 'updated_at';

  // User statistics map field name.
  static const String statistics = 'statistics';

  // Requests sent by the user field name.
  static const String requests = 'requests';

  // User group membership IDs field name.
  static const String groupIds = 'group_ids';

  // User friend user IDs field name.
  static const String friendIds = 'friend_ids';

  /// STATISTICS ENTRY FIELDS ///

  // Name of the test/flashcard/connect activity.
  static const String title = 'test_name';

  // Type of activity (test, flashcard, connect).
  static const String activityType = 'activity_type';

  // Number of correct answers in an attempt.
  static const String correct = 'correct';

  // Number of incorrect answers in an attempt.
  static const String incorrect = 'incorrect';

  // Timestamp when the attempt was completed.
  static const String completedAt = 'completed_at';

  /// ACTIVITY TYPE VALUES ///

  // Activity type value for tests.
  static const String activityTypeTest = 'test';

  // Activity type value for flashcards.
  static const String activityTypeFlashcard = 'flashcard';

  // Activity type value for connect games.
  static const String activityTypeConnect = 'connect';

  /// REQUEST FIELDS ///

  // Unique request identifier.
  static const String requestId = 'id';

  // Type of request (friend, group_invite, group_join).
  static const String requestType = 'request_type';

  // User ID of the sender.
  static const String requestFromUserId = 'from_user_id';

  // User ID of the recipient.
  static const String requestToUserId = 'to_user_id';

  // Group ID associated with the request (group invites/joins only).
  static const String requestGroupId = 'group_id';

  // Current status of the request.
  static const String requestStatus = 'status';

  // Timestamp when the request was created.
  static const String requestCreatedAt = 'request_created_at';

  /// REQUEST TYPE VALUES ///

  // Request type value for friend requests.
  static const String requestTypeFriend = 'friend';

  // Request type value for group invitations.
  static const String requestTypeGroupInvite = 'group_invite';

  // Request type value for group join requests.
  static const String requestTypeGroupJoin = 'group_join';

  /// REQUEST STATUS VALUES ///

  // Request status value for pending.
  static const String requestStatusPending = 'pending';

  // Request status value for accepted.
  static const String requestStatusAccepted = 'accepted';

  // Request status value for declined.
  static const String requestStatusDeclined = 'declined';
}
