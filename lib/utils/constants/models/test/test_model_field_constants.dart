class TestModelFieldConstants {
  /// TEST MODEL FIELDS ///

  // ID of the test field name
  static const String id = 'id';

  // ID of the author user field name
  static const String authorId = 'author_id';

  // ID of the group field name
  static const String groupId = 'group_id';

  // Test title field name
  static const String title = 'title';

  // Test description field name
  static const String description = 'description';

  // Tags for filtering and discovery field name
  static const String tags = 'tags';

  // Test creation date field name
  static const String createdAt = 'created_at';

  // Test last update date field name
  static const String updatedAt = 'updated_at';

  // Optional time limit in seconds field name
  static const String timeLimit = 'time_limit';

  // List of questions in the test field name
  static const String questions = 'questions';

  /// QUESTION FIELDS ///

  // ID of the question field name
  static const String questionId = 'id';

  // Question text field name
  static const String questionText = 'question_text';

  // List of answer options for this question field name
  static const String questionAnswers = 'answers';

  // Type of the question field name
  static const String questionType = 'question_type';

  // Question type value for single choice questions field name
  static const String singleChoice = 'single_choice';

  // Question type value for multiple choice questions field name
  static const String multipleChoice = 'multiple_choice';

  // Question type value for true/false questions field name
  static const String trueFalse = 'true_false';

  // Question type value for fill in the blank question field name
  static const String fillIntheBlank = 'fill_in_the_blank';

  // Question type value for ordering question field name
  static const String ordering = 'ordering';

  /// ANSWER OPTION FIELDS ///

  // ID of the answer option field name
  static const String answerId = 'id';

  // Text of the answer option field name
  static const String answerText = 'answer_text';

  // Whether this answer option is correct field name
  static const String answerIsCorrect = 'is_correct';

  /// TEST ATTEMPT FIELDS ///

  // List of all recorded attempts for this test field name
  static const String attempts = 'attempts';

  // ID of the attempt field name
  static const String attemptId = 'id';

  // ID of the user who took the test field name
  static const String attemptUserId = 'user_id';

  // List of question IDs the user answered correctly field name
  static const String attemptCorrectQuestionIds = 'correct_question_ids';

  // List of question IDs the user answered incorrectly field name
  static const String attemptIncorrectQuestionIds = 'incorrect_question_ids';

  // Timestamp when the attempt was completed field name
  static const String attemptCompletedAt = 'completed_at';
}
