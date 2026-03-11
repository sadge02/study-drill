class TestCreateEditScreenConstants {
  /// APP BAR ///

  static const String createAppBarTitle = 'Create Test';

  static const String editAppBarTitle = 'Edit Test';

  /// SECTION HEADERS ///

  static const String basicInfoSection = 'Basic Information';

  static const String tagsSection = 'Tags';

  static const String settingsSection = 'Settings';

  static const String questionsSection = 'Questions';

  static const String importSection = 'Import';

  /// HINT TEXTS ///

  static const String titleHint = 'Test Title';

  static const String descriptionHint = 'Description (Optional)';

  static const String tagInputHint = 'Add tag and press Enter...';

  static const String timeLimitHint = 'Time limit in seconds (Optional)';

  static const String questionHint = 'Question text';

  static const String answerHint = 'Answer text';

  /// QUESTION TYPES ///

  static const String singleChoiceLabel = 'Single Choice';

  static const String multipleChoiceLabel = 'Multiple Choice';

  static const String trueFalseLabel = 'True / False';

  static const String fillInBlankLabel = 'Fill in the Blank';

  static const String orderingLabel = 'Ordering';

  /// BUTTON LABELS ///

  static const String createButtonLabel = 'Create Test';

  static const String saveButtonLabel = 'Save Changes';

  static const String addQuestionLabel = 'Add Question';

  static const String addAnswerLabel = 'Add Answer';

  static const String removeQuestionLabel = 'Remove';

  static const String importJsonLabel = 'Import from JSON';

  static const String exportJsonLabel = 'Export as JSON';

  /// SNACKBAR MESSAGES ///

  static const String createSuccessMessage = 'Test created successfully.';

  static const String updateSuccessMessage = 'Test updated successfully.';

  static const String importSuccessMessage = 'Questions imported from JSON.';

  static const String importErrorMessage = 'Failed to parse JSON file.';

  static const String noFileSelectedMessage = 'No file selected.';

  static const String titleRequiredMessage = 'Title is required.';

  /// VALIDATION ///

  static const String titleEmptyError = 'Please enter a test title';

  static const int titleMinLength = 2;

  static const int titleMaxLength = 100;

  static const String titleTooShortError =
      'Title must be at least 2 characters';

  static const String titleTooLongError =
      'Title must be at most 100 characters';

  static const int descriptionMaxLength = 500;

  static const String descriptionTooLongError =
      'Description must be at most 500 characters';

  static const int maxTags = 10;

  static const String maxTagsError = 'You can add up to 10 tags';

  static const String questionEmptyError = 'Question text cannot be empty';

  static const String answerEmptyError = 'Answer text cannot be empty';

  static const String noQuestionsError = 'Please add at least one question';

  static const String noAnswersError = 'Each question needs at least 2 answers';

  static const String noCorrectAnswerError =
      'Each question needs at least one correct answer';

  static const String trueFalseRequiresTwo =
      'True/False must have exactly 2 answers';

  /// JSON IMPORT FORMAT ///

  static const String jsonFormatHint = '''
[
  {
    "question": "Your question?",
    "type": "single_choice",
    "answers": [
      { "text": "Answer 1", "correct": true },
      { "text": "Answer 2", "correct": false }
    ]
  }
]

Types: single_choice, multiple_choice, true_false, fill_in_the_blank, ordering
''';

  static const String jsonFormatTitle = 'JSON Format';

  /// SIZING ///

  static const double buttonWidth = 200.0;

  static const double buttonHeight = 50.0;

  static const double sectionSpacing = 24.0;

  static const double fieldSpacing = 14.0;

  static const double tagChipSpacing = 6.0;

  static const double sectionHeaderFontSize = 16.0;

  static const double questionCardRadius = 12.0;

  static const double questionCardBorderOpacity = 0.15;

  static const double questionHeaderFontSize = 14.0;

  static const double questionNumberSize = 28.0;

  static const double answerRowSpacing = 8.0;

  static const double descriptionMaxLines = 3;

  static const int minAnswersPerQuestion = 2;
}
