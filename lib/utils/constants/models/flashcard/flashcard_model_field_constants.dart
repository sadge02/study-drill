class FlashcardModelFieldConstants {
  /// FLASHCARD SET MODEL FIELDS ///

  // Flashcard set ID field name
  static const String id = 'id';

  // Author ID field name
  static const String authorId = 'author_id';

  // Group ID field name
  static const String groupId = 'group_id';

  // Flashcard set title field name
  static const String title = 'title';

  // Flashcard set description field name
  static const String description = 'description';

  // Flashcard set tags field name
  static const String tags = 'tags';

  // Flashcard set creation date field name
  static const String createdAt = 'created_at';

  // Flashcard set last update date field name
  static const String updatedAt = 'updated_at';

  // Optional time limit in seconds for the flashcard session
  static const String timeLimit = 'time_limit';

  // List of question-answer pairs (flashcards) field name
  static const String cards = 'cards';

  /// FLASHCARD FIELDS ///

  // Flashcard ID field name
  static const String cardId = 'id';

  // Flashcard question field name
  static const String cardQuestion = 'question';

  // Flashcard correct answer field name
  static const String cardAnswer = 'answer';

  /// FLASHCARD ATTEMPT FIELDS ///

  // List of all recorded attempts for this flashcard set field name
  static const String attempts = 'attempts';

  // ID of the attempt field name
  static const String attemptId = 'id';

  // ID of the user who took the flashcard set field name
  static const String attemptUserId = 'user_id';

  // List of card IDs the user self-reported as correct field name
  static const String attemptCorrectCardIds = 'correct_card_ids';

  // List of card IDs the user self-reported as incorrect field name
  static const String attemptIncorrectCardIds = 'incorrect_card_ids';

  // Timestamp when the attempt was completed field name
  static const String attemptCompletedAt = 'completed_at';
}
