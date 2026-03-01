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

  // User statistics (scores, achievements, etc.) field name.
  static const String statistics = 'statistics';

  // User privacy settings field name.
  static const String privacySettings = 'privacy_settings';

  // User general settings field name.
  static const String settings = 'settings';

  // User group membership IDs field name.
  static const String groupIds = 'group_ids';

  // User friend user IDs field name.
  static const String friendIds = 'friend_ids';

  // Pending friend request IDs received by user field name.
  static const String pendingFriendRequestIds = 'pending_friend_request_ids';

  // Friend request IDs sent by user field name.
  static const String sentFriendRequestIds = 'sent_friend_request_ids';

  // User completed tests/quizzes field name.
  static const String userTests = 'user_tests';

  // User email notification preference field name.
  static const String getNotifications = 'get_notifications';

  // User push notification preference field name.
  static const String getPushNotifications = 'get_push_notifications';

  /// VISIBILITY SETTINGS ///

  // Public visibility setting value.
  static const String userVisibilityPublic = 'public';

  // Private visibility setting value.
  static const String userVisibilityPrivate = 'private';
}
