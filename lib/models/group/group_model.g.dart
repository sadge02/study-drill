// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupSettings _$GroupSettingsFromJson(Map<String, dynamic> json) =>
    GroupSettings(
      autoAddAsEditor: json['auto_add_as_editor'] as bool? ?? true,
      requiresJoinApproval: json['requires_join_approval'] as bool? ?? false,
    );

Map<String, dynamic> _$GroupSettingsToJson(GroupSettings instance) =>
    <String, dynamic>{
      'auto_add_as_editor': instance.autoAddAsEditor,
      'requires_join_approval': instance.requiresJoinApproval,
    };

GroupJoinRequest _$GroupJoinRequestFromJson(Map<String, dynamic> json) =>
    GroupJoinRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$GroupJoinRequestToJson(GroupJoinRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'created_at': instance.createdAt.toIso8601String(),
    };

GroupModel _$GroupModelFromJson(Map<String, dynamic> json) => GroupModel(
  id: json['id'] as String,
  authorId: json['author_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  profilePic: json['profile_pic'] as String? ?? '',
  visibility: $enumDecode(_$GroupVisibilityEnumMap, json['visibility']),
  settings: json['settings'] == null
      ? null
      : GroupSettings.fromJson(json['settings'] as Map<String, dynamic>),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  adminIds:
      (json['admin_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  creatorIds:
      (json['creator_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  userIds:
      (json['user_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  testIds:
      (json['test_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  flashcardIds:
      (json['flashcard_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  connectIds:
      (json['connect_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  joinRequests:
      (json['join_requests'] as List<dynamic>?)
          ?.map((e) => GroupJoinRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$GroupModelToJson(GroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'title': instance.title,
      'description': instance.description,
      'profile_pic': instance.profilePic,
      'visibility': _$GroupVisibilityEnumMap[instance.visibility]!,
      'settings': instance.settings.toJson(),
      'tags': instance.tags,
      'admin_ids': instance.adminIds,
      'creator_ids': instance.creatorIds,
      'user_ids': instance.userIds,
      'test_ids': instance.testIds,
      'flashcard_ids': instance.flashcardIds,
      'connect_ids': instance.connectIds,
      'join_requests': instance.joinRequests.map((e) => e.toJson()).toList(),
    };

const _$GroupVisibilityEnumMap = {
  GroupVisibility.public: 'public',
  GroupVisibility.private: 'private',
  GroupVisibility.friends: 'friends',
};
