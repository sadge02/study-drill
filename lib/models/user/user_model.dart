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
  factory UserTestResult.fromJson(Map<String, dynamic> json) =>
      _$UserTestResultFromJson(json);

  UserTestResult({this.repetitions = 0, this.correct = 0, this.incorrect = 0});

  final int repetitions;

  final int correct;
  final int incorrect;

  Map<String, dynamic> toJson() => _$UserTestResultToJson(this);
}

@JsonSerializable()
class UserTests {
  factory UserTests.fromJson(Map<String, dynamic> json) =>
      _$UserTestsFromJson(json);

  UserTests({this.userTests = const {}});

  @JsonKey(name: 'user_tests')
  final Map<String, UserTestResult> userTests;

  Map<String, dynamic> toJson() => _$UserTestsToJson(this);
}

@JsonSerializable()
class UserPrivacySettings {
  UserPrivacySettings({
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

@JsonSerializable(explicitToJson: true)
class UserModel {
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.summary,
    required this.profilePic,
    required this.createdAt,
    this.statistics,
    this.privacySettings,
    required this.groupIds,
    this.friendIds = const [],
  });

  final String id;
  final String email;
  final String username;
  final String summary;

  @JsonKey(name: 'profile_pic')
  final String profilePic;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  final UserTests? statistics;

  @JsonKey(name: 'privacy_settings')
  final UserPrivacySettings? privacySettings;

  @JsonKey(name: 'group_ids')
  final List<String> groupIds;

  @JsonKey(name: 'friend_ids')
  final List<String> friendIds;

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
