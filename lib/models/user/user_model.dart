import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

enum UserVisibility {
  @JsonValue('public')
  public,
  @JsonValue('private')
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

  @JsonKey(name: 'user_tests')
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

  @JsonKey(name: 'get_notifications')
  final bool getInAppNotifications;

  @JsonKey(name: 'get_push_notifications')
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
    this.fcmToken,
    UserTests? statistics,
    UserPrivacySettings? privacySettings,
    UserSettings? settings,
    required this.groupIds,
    this.friendIds = const [],
    this.pendingFriendRequestIds = const [],
  }) : statistics = statistics ?? UserTests(),
       privacySettings = privacySettings ?? const UserPrivacySettings(),
       settings = settings ?? const UserSettings();

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  final String id;
  final String email;
  final String username;

  @JsonKey(name: 'username_lowercase')
  final String usernameLowercase;

  final String summary;

  @JsonKey(name: 'profile_pic')
  final String profilePic;

  @JsonKey(name: 'fcm_token')
  final String? fcmToken;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  final UserTests statistics;

  @JsonKey(name: 'privacy_settings')
  final UserPrivacySettings privacySettings;

  final UserSettings settings;

  @JsonKey(name: 'group_ids')
  final List<String> groupIds;

  @JsonKey(name: 'friend_ids')
  final List<String> friendIds;

  @JsonKey(name: 'pending_friend_request_ids')
  final List<String> pendingFriendRequestIds;
}
