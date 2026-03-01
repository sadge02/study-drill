import 'package:json_annotation/json_annotation.dart';

import '../../utils/constants/models/group_model_field_constants.dart';

part 'group_model.g.dart';

enum GroupVisibility {
  @JsonValue(GroupModelFieldConstants.groupVisibilityPublic)
  public,
  @JsonValue(GroupModelFieldConstants.groupVisibilityPrivate)
  private,
}

@JsonSerializable()
class GroupSettings {
  GroupSettings({
    this.autoAddAsEditor = false,
    this.notifyOnNewContent = true,
    this.requiresApproval = false,
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) =>
      _$GroupSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$GroupSettingsToJson(this);

  @JsonKey(name: GroupModelFieldConstants.autoAddAsEditor)
  final bool autoAddAsEditor;

  @JsonKey(name: GroupModelFieldConstants.notifyOnNewContent)
  final bool notifyOnNewContent;

  @JsonKey(name: GroupModelFieldConstants.requiresApproval)
  final bool requiresApproval;
}

@JsonSerializable(explicitToJson: true)
class GroupModel {
  GroupModel({
    required this.id,
    required this.name,
    required this.nameLowercase,
    required this.summary,
    required this.profilePic,
    required this.authorId,
    required this.visibility,
    GroupSettings? settings,
    this.tags = const [],
    this.userIds = const [],
    this.editorUserIds = const [],
    this.adminIds = const [],
    this.pendingUserRequestIds = const [],
    this.testIds = const [],
    this.flashcardIds = const [],
    this.matchGameIds = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : settings = settings ?? GroupSettings();

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupModelToJson(this);

  @JsonKey(name: GroupModelFieldConstants.id)
  final String id;

  @JsonKey(name: GroupModelFieldConstants.name)
  final String name;

  @JsonKey(name: GroupModelFieldConstants.nameLowercase)
  final String nameLowercase;

  @JsonKey(name: GroupModelFieldConstants.summary)
  final String summary;

  @JsonKey(name: GroupModelFieldConstants.profilePic)
  final String profilePic;

  @JsonKey(name: GroupModelFieldConstants.authorId)
  final String authorId;

  @JsonKey(name: GroupModelFieldConstants.visibility)
  final GroupVisibility visibility;

  @JsonKey(name: GroupModelFieldConstants.settings)
  final GroupSettings settings;

  @JsonKey(name: GroupModelFieldConstants.tags)
  final List<String> tags;

  @JsonKey(name: GroupModelFieldConstants.userIds)
  final List<String> userIds;

  @JsonKey(name: GroupModelFieldConstants.editorUserIds)
  final List<String> editorUserIds;

  @JsonKey(name: GroupModelFieldConstants.pendingUserRequestIds)
  final List<String> pendingUserRequestIds;

  @JsonKey(name: GroupModelFieldConstants.adminIds)
  final List<String> adminIds;

  @JsonKey(name: GroupModelFieldConstants.testIds)
  final List<String> testIds;

  @JsonKey(name: GroupModelFieldConstants.flashcardIds)
  final List<String> flashcardIds;

  @JsonKey(name: GroupModelFieldConstants.matchGameIds)
  final List<String> matchGameIds;

  @JsonKey(name: GroupModelFieldConstants.createdAt)
  final DateTime createdAt;

  @JsonKey(name: GroupModelFieldConstants.updatedAt)
  final DateTime updatedAt;

  int get memberCount => userIds.length;

  int get totalContentCount =>
      testIds.length + flashcardIds.length + matchGameIds.length;

  bool isAdmin(String uid) => adminIds.contains(uid);

  bool isEditor(String uid) => editorUserIds.contains(uid);

  GroupModel copyWith({
    String? name,
    String? summary,
    String? profilePic,
    GroupVisibility? visibility,
    GroupSettings? settings,
    List<String>? tags,
    List<String>? userIds,
    List<String>? editorUserIds,
    List<String>? pendingUserIds,
    List<String>? adminIds,
    List<String>? testIds,
    List<String>? flashcardIds,
    List<String>? matchGameIds,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id,
      authorId: authorId,
      createdAt: createdAt,
      nameLowercase: name?.toLowerCase() ?? nameLowercase,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      profilePic: profilePic ?? this.profilePic,
      visibility: visibility ?? this.visibility,
      settings: settings ?? this.settings,
      tags: tags ?? this.tags,
      userIds: userIds ?? this.userIds,
      editorUserIds: editorUserIds ?? this.editorUserIds,
      pendingUserRequestIds: pendingUserIds ?? pendingUserRequestIds,
      adminIds: adminIds ?? this.adminIds,
      testIds: testIds ?? this.testIds,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      matchGameIds: matchGameIds ?? this.matchGameIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
