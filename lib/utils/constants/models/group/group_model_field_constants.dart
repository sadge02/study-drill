class GroupModelFieldConstants {
  /// GROUP MODEL FIELDS ///

  // Group ID field name
  static const String id = 'id';

  // User ID of the group author field name
  static const String authorId = 'author_id';

  // Group creation date field name
  static const String createdAt = 'created_at';

  // Group last update date field name
  static const String updatedAt = 'updated_at';

  // Group title field name.
  static const String title = 'title';

  // Group description field name.
  static const String description = 'description';

  // Group profile picture URL field name
  static const String profilePic = 'profile_pic';

  // Group visibility setting field name
  static const String visibility = 'visibility';

  // Group general settings field name
  static const String settings = 'settings';

  // Group tags field name
  static const String tags = 'tags';

  // Group administrator user IDs field name
  static const String adminIds = 'admin_ids';

  // Group content creator user IDs field name
  static const String creatorIds = 'creator_ids';

  // Group member user IDs field name
  static const String userIds = 'user_ids';

  // Group test IDs field name
  static const String testIds = 'test_ids';

  // Group flashcard set IDs field name
  static const String flashcardIds = 'flashcard_ids';

  // Group connect game IDs field name
  static const String connectIds = 'connect_ids';

  /// VISIBILITY VALUES ///

  // Public visibility value
  static const String groupVisibilityPublic = 'public';

  // Private visibility value
  static const String groupVisibilityPrivate = 'private';

  // Friends-only visibility value
  static const String groupVisibilityFriends = 'friends';

  /// GROUP SETTINGS FIELDS ///

  // Auto-add new members as editors setting field name
  static const String autoAddAsEditor = 'auto_add_as_editor';

  // Require admin approval for join requests setting field name
  static const String requiresJoinApproval = 'requires_join_approval';

  /// JOIN REQUEST FIELDS ///

  // List of join requests for the group field name
  static const String joinRequests = 'join_requests';

  // ID of the join request field name
  static const String joinRequestId = 'id';

  // ID of the user requesting to join field name
  static const String joinRequestUserId = 'user_id';

  // Timestamp when the join request was created field name
  static const String joinRequestCreatedAt = 'created_at';

  /// CONSTRAINTS ///

  // Maximum number of operations per Firestore batch write.
  static const int batchLimit = 500;

  // Maximum number of values allowed in a single Firestore whereIn query.
  static const int whereInLimit = 10;
}
