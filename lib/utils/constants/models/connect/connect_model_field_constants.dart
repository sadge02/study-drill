class ConnectModelFieldConstants {
  /// CONNECT MODEL FIELDS ///

  // Connect ID field name
  static const String id = 'id';

  // Author ID field name
  static const String authorId = 'author_id';

  // Group ID field name
  static const String groupId = 'group_id';

  // Connect title field name
  static const String title = 'title';

  // Connect description field name
  static const String description = 'description';

  // Connect tags field name
  static const String tags = 'tags';

  // Connect creation date field name
  static const String createdAt = 'created_at';

  // Connect last update date field name
  static const String updatedAt = 'updated_at';

  // Optional time limit in seconds for the connect game
  static const String timeLimit = 'time_limit';

  // List of question-answer pairs of the Connect game field name
  static const String pairs = 'pairs';

  /// PAIR FIELDS ///

  // Pair ID field name
  static const String pairId = 'id';

  // The question of the pair field name
  static const String pairQuestion = 'question';

  // The correct answer of the pair field name
  static const String pairAnswer = 'answer';

  /// CONSTRAINTS ///

  // Minimum number of pairs displayed on one screen
  static const int minPairsPerScreen = 2;

  // Maximum number of pairs displayed on one screen
  static const int maxPairsPerScreen = 5;

  /// CONNECT ATTEMPT FIELDS ///

  // List of all recorded attempts for this connect field name
  static const String attempts = 'attempts';

  // ID of the attempt field name
  static const String attemptId = 'id';

  // ID of the user who took the connect field name
  static const String attemptUserId = 'user_id';

  // Timestamp when the attempt was completed field name
  static const String attemptCompletedAt = 'completed_at';

  // List of pair IDs the user matched correctly field name
  static const String attemptCorrectPairIds = 'correct_pair_ids';

  // List of pair IDs the user matched incorrectly field name
  static const String attemptIncorrectPairIds = 'incorrect_pair_ids';
}
