class GroupModelFieldConstants {
  /// GROUP MODEL FIELDS ///

  // Group unique identifier field name.
  static const String id = 'id';

  // Group display name field name.
  static const String name = 'name';

  // Group lowercase name for case-insensitive search field name.
  static const String nameLowercase = 'name_lowercase';

  // Group description/summary field name.
  static const String summary = 'summary';

  // Group profile picture URL field name.
  static const String profilePic = 'profile_pic';

  // Group creator/author user ID field name.
  static const String authorId = 'author_id';

  // Group visibility setting field name.
  static const String visibility = 'visibility';

  // Group general settings field name.
  static const String settings = 'settings';

  // Group category/topic tags field name.
  static const String tags = 'tags';

  // Group member user IDs field name.
  static const String userIds = 'user_ids';

  // Group editor user IDs with edit permissions field name.
  static const String editorUserIds = 'editor_user_ids';

  // Group administrator user IDs field name.
  static const String adminIds = 'admin_ids';

  // Pending group membership request user IDs field name.
  static const String pendingUserRequestIds = 'pending_user_ids';

  // Group test/quiz IDs field name.
  static const String testIds = 'test_ids';

  // Group flashcard set IDs field name.
  static const String flashcardIds = 'flashcard_ids';

  // Group match game IDs field name.
  static const String matchGameIds = 'match_game_ids';

  // Group creation date field name.
  static const String createdAt = 'created_at';

  // Group last update date field name.
  static const String updatedAt = 'updated_at';

  /// VISIBILITY SETTINGS ///

  // Public visibility setting value.
  static const String groupVisibilityPublic = 'public';

  // Private visibility setting value.
  static const String groupVisibilityPrivate = 'private';

  /// GROUP SETTINGS ///

  // Setting to automatically add new members as editors field name.
  static const String autoAddAsEditor = 'auto_add_as_editor';

  // Setting to notify members when new content is added field name.
  static const String notifyOnNewContent = 'notify_on_new_content';

  // Setting to require admin approval for new member join requests field name.
  static const String requiresApproval = 'requires_approval';
}
