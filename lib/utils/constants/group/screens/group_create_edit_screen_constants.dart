class GroupCreateEditScreenConstants {
  /// APP BAR ///

  static const String createAppBarTitle = 'Create Group';

  static const String editAppBarTitle = 'Edit Group';

  /// SECTION HEADERS ///

  static const String basicInfoSection = 'Basic Information';

  static const String visibilitySection = 'Visibility & Access';

  static const String tagsSection = 'Tags';

  static const String settingsSection = 'Settings';

  /// HINT TEXTS ///

  static const String titleHint = 'Group Title';

  static const String descriptionHint = 'Description (Optional)';

  static const String profilePicHint = 'Profile Picture URL (Optional)';

  static const String tagInputHint = 'Add tag and press Enter...';

  /// VISIBILITY OPTIONS ///

  static const String visibilityPublicLabel = 'Public';

  static const String visibilityPublicDescription =
      'Anyone can discover and request to join';

  static const String visibilityFriendsLabel = 'Friends';

  static const String visibilityFriendsDescription =
      'Visible to friends of members';

  static const String visibilityPrivateLabel = 'Private';

  static const String visibilityPrivateDescription =
      'Only visible to members, invite only';

  /// SETTINGS LABELS ///

  static const String autoAddEditorLabel = 'Auto-add members as editors';

  static const String autoAddEditorDescription =
      'New members can create content immediately';

  static const String requireApprovalLabel = 'Require join approval';

  static const String requireApprovalDescription =
      'Admins must approve join requests';

  /// BUTTON LABELS ///

  static const String createButtonLabel = 'Create Group';

  static const String saveButtonLabel = 'Save Changes';

  /// SNACKBAR MESSAGES ///

  static const String createSuccessMessage = 'Group created successfully.';

  static const String updateSuccessMessage = 'Group updated successfully.';

  static const String titleRequiredMessage = 'Title is required.';

  /// VALIDATION ///

  static const String titleEmptyError = 'Please enter a group title';

  static const int titleMinLength = 2;

  static const int titleMaxLength = 50;

  static const String titleTooShortError =
      'Title must be at least 2 characters';

  static const String titleTooLongError = 'Title must be at most 50 characters';

  static const int descriptionMaxLength = 300;

  static const String descriptionTooLongError =
      'Description must be at most 300 characters';

  static const int maxTags = 10;

  static const String maxTagsError = 'You can add up to 10 tags';

  /// SIZING ///

  static const double buttonWidth = 200.0;

  static const double buttonHeight = 50.0;

  static const double sectionSpacing = 24.0;

  static const double fieldSpacing = 14.0;

  static const double tagChipSpacing = 6.0;

  static const double sectionHeaderFontSize = 16.0;

  static const double visibilityOptionRadius = 12.0;

  static const double visibilityOptionBorderOpacity = 0.15;

  static const double visibilitySelectedBorderOpacity = 1.0;

  static const double settingsTileRadius = 12.0;

  static const double descriptionMaxLines = 4;
}
