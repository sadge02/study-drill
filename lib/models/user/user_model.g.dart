// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserTestResult _$UserTestResultFromJson(Map<String, dynamic> json) =>
    UserTestResult(
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      incorrect: (json['incorrect'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserTestResultToJson(UserTestResult instance) =>
    <String, dynamic>{
      'repetitions': instance.repetitions,
      'correct': instance.correct,
      'incorrect': instance.incorrect,
    };

UserTests _$UserTestsFromJson(Map<String, dynamic> json) => UserTests(
  userTests:
      (json['user_tests'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, UserTestResult.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
);

Map<String, dynamic> _$UserTestsToJson(UserTests instance) => <String, dynamic>{
  'user_tests': instance.userTests,
};

UserPrivacySettings _$UserPrivacySettingsFromJson(Map<String, dynamic> json) =>
    UserPrivacySettings(
      email:
          $enumDecodeNullable(_$UserVisibilityEnumMap, json['email']) ??
          UserVisibility.private,
      statistics:
          $enumDecodeNullable(_$UserVisibilityEnumMap, json['statistics']) ??
          UserVisibility.public,
      groups:
          $enumDecodeNullable(_$UserVisibilityEnumMap, json['groups']) ??
          UserVisibility.public,
      tests:
          $enumDecodeNullable(_$UserVisibilityEnumMap, json['tests']) ??
          UserVisibility.public,
    );

Map<String, dynamic> _$UserPrivacySettingsToJson(
  UserPrivacySettings instance,
) => <String, dynamic>{
  'email': _$UserVisibilityEnumMap[instance.email]!,
  'statistics': _$UserVisibilityEnumMap[instance.statistics]!,
  'groups': _$UserVisibilityEnumMap[instance.groups]!,
  'tests': _$UserVisibilityEnumMap[instance.tests]!,
};

const _$UserVisibilityEnumMap = {
  UserVisibility.public: 'public',
  UserVisibility.private: 'private',
};

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
  summary: json['summary'] as String,
  profilePic: json['profile_pic'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  statistics: json['statistics'] == null
      ? null
      : UserTests.fromJson(json['statistics'] as Map<String, dynamic>),
  privacySettings: json['privacy_settings'] == null
      ? null
      : UserPrivacySettings.fromJson(
          json['privacy_settings'] as Map<String, dynamic>,
        ),
  groupIds: (json['group_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  friendIds:
      (json['friend_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'username': instance.username,
  'summary': instance.summary,
  'profile_pic': instance.profilePic,
  'created_at': instance.createdAt.toIso8601String(),
  'statistics': instance.statistics?.toJson(),
  'privacy_settings': instance.privacySettings?.toJson(),
  'group_ids': instance.groupIds,
  'friend_ids': instance.friendIds,
};
