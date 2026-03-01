import 'package:json_annotation/json_annotation.dart';

import '../../utils/constants/models/user_model_field_constants.dart';

part 'user_model.g.dart';

enum UserVisibility {
  @JsonValue(UserModelFieldConstants.userVisibilityPublic)
  public,
  @JsonValue(UserModelFieldConstants.userVisibilityPrivate)
  private,
}

@JsonSerializable()
class UserTestResult {
  UserTestResult({this.repetitions = 0, this.correct = 0, this.incorrect = 0});

  factory UserTestResult.fromJson(Map<String, dynamic> json) =>
      _$UserTestResultFromJson(json);

  Map<String, dynamic> toJson() => _$UserTestResultToJson(this);

  final int repetitions;
  final int correct;
  final int incorrect;

  double get accuracy {
    final total = correct + incorrect;
    return total == 0 ? 0.0 : (correct / total) * 100;
  }
}

@JsonSerializable()
class UserTests {
  UserTests({this.userTests = const {}});

  factory UserTests.fromJson(Map<String, dynamic> json) =>
      _$UserTestsFromJson(json);

  Map<String, dynamic> toJson() => _$UserTestsToJson(this);

  @JsonKey(name: UserModelFieldConstants.userTests)
  final Map<String, UserTestResult> userTests;

  int get totalTestsTaken =>
      userTests.values.fold(0, (sum, item) => sum + item.repetitions);

  double get globalAccuracy {
    if (userTests.isEmpty) return 0.0;
    int totalCorrect = 0;
    int totalAttempted = 0;

    for (var result in userTests.values) {
      totalCorrect += result.correct;
      totalAttempted += (result.correct + result.incorrect);
    }

    return totalAttempted == 0 ? 0.0 : (totalCorrect / totalAttempted) * 100;
  }
}

@JsonSerializable()
class UserPrivacySettings {
  const UserPrivacySettings({
    this.email = UserVisibility.private,
    this.statistics = UserVisibility.public,
    this.groups = UserVisibility.public,
    this.tests = UserVisibility.public,
  });

  factory UserPrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$UserPrivacySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserPrivacySettingsToJson(this);

  final UserVisibility email;
  final UserVisibility statistics;
  final UserVisibility groups;
  final UserVisibility tests;
}

@JsonSerializable()
class UserSettings {
  const UserSettings({
    this.getInAppNotifications = true,
    this.getPushNotifications = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);

  @JsonKey(name: UserModelFieldConstants.getNotifications)
  final bool getInAppNotifications;

  @JsonKey(name: UserModelFieldConstants.getPushNotifications)
  final bool getPushNotifications;
}

@JsonSerializable(explicitToJson: true)
class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.usernameLowercase,
    required this.summary,
    required this.profilePic,
    required this.createdAt,
    required this.updatedAt,
    UserTests? statistics,
    UserPrivacySettings? privacySettings,
    UserSettings? settings,
    required this.groupIds,
    this.friendIds = const [],
    this.pendingFriendRequestIds = const [],
    this.sentFriendRequestIds = const [],
  }) : statistics = statistics ?? UserTests(),
       privacySettings = privacySettings ?? const UserPrivacySettings(),
       settings = settings ?? const UserSettings();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @JsonKey(name: UserModelFieldConstants.id)
  final String id;

  @JsonKey(name: UserModelFieldConstants.email)
  final String email;

  @JsonKey(name: UserModelFieldConstants.username)
  final String username;

  @JsonKey(name: UserModelFieldConstants.usernameLowercase)
  final String usernameLowercase;

  @JsonKey(name: UserModelFieldConstants.summary)
  final String summary;

  @JsonKey(name: UserModelFieldConstants.profilePic)
  final String profilePic;

  @JsonKey(name: UserModelFieldConstants.createdAt)
  final DateTime createdAt;

  @JsonKey(name: UserModelFieldConstants.updatedAt)
  final DateTime updatedAt;

  @JsonKey(name: UserModelFieldConstants.statistics)
  final UserTests statistics;

  @JsonKey(name: UserModelFieldConstants.privacySettings)
  final UserPrivacySettings privacySettings;

  @JsonKey(name: UserModelFieldConstants.settings)
  final UserSettings settings;

  @JsonKey(name: UserModelFieldConstants.groupIds)
  final List<String> groupIds;

  @JsonKey(name: UserModelFieldConstants.friendIds)
  final List<String> friendIds;

  @JsonKey(name: UserModelFieldConstants.pendingFriendRequestIds)
  final List<String> pendingFriendRequestIds;

  @JsonKey(name: UserModelFieldConstants.sentFriendRequestIds)
  final List<String> sentFriendRequestIds;
}
