class FlashcardCreateEditScreenConstants {
  /// APP BAR ///

  static const String createAppBarTitle = 'Create Flashcard Set';

  static const String editAppBarTitle = 'Edit Flashcard Set';

  /// SECTION HEADERS ///

  static const String basicInfoSection = 'Basic Information';

  static const String tagsSection = 'Tags';

  static const String settingsSection = 'Settings';

  static const String cardsSection = 'Cards';

  static const String importSection = 'Import';

  /// HINT TEXTS ///

  static const String titleHint = 'Flashcard Set Title';

  static const String descriptionHint = 'Description (Optional)';

  static const String tagInputHint = 'Add tag and press Enter...';

  static const String timeLimitHint = 'Time limit in seconds (Optional)';

  static const String questionHint = 'Question / Front';

  static const String answerHint = 'Answer / Back';

  /// BUTTON LABELS ///

  static const String createButtonLabel = 'Create Flashcard Set';

  static const String saveButtonLabel = 'Save Changes';

  static const String addCardLabel = 'Add Card';

  static const String removeCardLabel = 'Remove';

  static const String importJsonLabel = 'Import from JSON';

  /// SNACKBAR MESSAGES ///

  static const String createSuccessMessage =
      'Flashcard set created successfully.';

  static const String updateSuccessMessage =
      'Flashcard set updated successfully.';

  static const String importSuccessMessage = 'Cards imported from JSON.';

  static const String importErrorMessage = 'Failed to parse JSON file.';

  static const String noFileSelectedMessage = 'No file selected.';

  /// VALIDATION ///

  static const String titleEmptyError = 'Please enter a title';

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

  static const String questionEmptyError = 'Question cannot be empty';

  static const String answerEmptyError = 'Answer cannot be empty';

  static const String noCardsError = 'Please add at least one card';

  /// JSON FORMAT ///

  static const String jsonFormatTitle = 'JSON Format';

  static const String jsonFormatHint = '''
[
  {
    "question": "What is Flutter?",
    "answer": "A UI toolkit by Google"
  }
]
''';

  /// SIZING ///

  static const double buttonWidth = 220.0;

  static const double buttonHeight = 50.0;

  static const double sectionSpacing = 24.0;

  static const double fieldSpacing = 14.0;

  static const double tagChipSpacing = 6.0;

  static const double sectionHeaderFontSize = 16.0;

  static const double cardRadius = 12.0;

  static const double cardBorderOpacity = 0.15;

  static const double cardNumberSize = 28.0;

  static const double cardHeaderFontSize = 14.0;

  static const double descriptionMaxLines = 3;

  static const int minCards = 1;
}
