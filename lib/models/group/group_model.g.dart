// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupSettings _$GroupSettingsFromJson(Map<String, dynamic> json) =>
    GroupSettings(
      autoAddAsEditor: json['auto_add_as_editor'] as bool? ?? false,
    );

Map<String, dynamic> _$GroupSettingsToJson(GroupSettings instance) =>
    <String, dynamic>{'auto_add_as_editor': instance.autoAddAsEditor};

GroupModel _$GroupModelFromJson(Map<String, dynamic> json) => GroupModel(
  id: json['id'] as String,
  name: json['name'] as String,
  summary: json['summary'] as String,
  profilePic: json['profile_pic'] as String,
  authorId: json['author_id'] as String,
  visibility: $enumDecode(_$GroupVisibilityEnumMap, json['visibility']),
  settings: json['settings'] == null
      ? null
      : GroupSettings.fromJson(json['settings'] as Map<String, dynamic>),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  userIds:
      (json['user_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  editorUserIds:
      (json['editor_user_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  adminIds:
      (json['admin_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  pendingUserIds:
      (json['pending_user_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  testIds:
      (json['test_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  flashcardIds:
      (json['flashcard_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  matchGameIds:
      (json['match_game_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$GroupModelToJson(GroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'summary': instance.summary,
      'profile_pic': instance.profilePic,
      'author_id': instance.authorId,
      'visibility': _$GroupVisibilityEnumMap[instance.visibility]!,
      'settings': instance.settings?.toJson(),
      'tags': instance.tags,
      'user_ids': instance.userIds,
      'editor_user_ids': instance.editorUserIds,
      'pending_user_ids': instance.pendingUserIds,
      'admin_ids': instance.adminIds,
      'test_ids': instance.testIds,
      'flashcard_ids': instance.flashcardIds,
      'match_game_ids': instance.matchGameIds,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$GroupVisibilityEnumMap = {
  GroupVisibility.public: 'public',
  GroupVisibility.private: 'private',
};
