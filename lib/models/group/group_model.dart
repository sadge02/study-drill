import 'package:json_annotation/json_annotation.dart';

part 'group_model.g.dart';

enum GroupVisibility {
  @JsonValue('public')
  public,
  @JsonValue('private')
  private,
}

@JsonSerializable()
class GroupSettings {
  GroupSettings({this.autoAddAsEditor = false});

  factory GroupSettings.fromJson(Map<String, dynamic> json) =>
      _$GroupSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$GroupSettingsToJson(this);

  @JsonKey(name: 'auto_add_as_editor')
  final bool autoAddAsEditor;
}

@JsonSerializable(explicitToJson: true)
class GroupModel {
  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);

  GroupModel({
    required this.id,
    required this.name,
    required this.summary,
    required this.profilePic,
    required this.authorId,
    required this.visibility,
    required this.settings,
    this.tags = const [],
    this.userIds = const [],
    this.editorUserIds = const [],
    this.adminIds = const [],
    this.pendingUserRequestIds = const [],
    this.testIds = const [],
    this.flashcardIds = const [],
    this.matchGameIds = const [],
    required this.createdAt,
  });

  final String id;
  final String name;
  final String summary;

  @JsonKey(name: 'profile_pic')
  final String profilePic;

  @JsonKey(name: 'author_id')
  final String authorId;

  final GroupVisibility visibility;
  final GroupSettings? settings;
  final List<String> tags;

  @JsonKey(name: 'user_ids')
  final List<String> userIds;

  @JsonKey(name: 'editor_user_ids')
  final List<String> editorUserIds;

  @JsonKey(name: 'pending_user_ids')
  final List<String> pendingUserRequestIds;

  @JsonKey(name: 'admin_ids')
  final List<String> adminIds;

  @JsonKey(name: 'test_ids')
  final List<String> testIds;

  @JsonKey(name: 'flashcard_ids')
  final List<String> flashcardIds;

  @JsonKey(name: 'match_game_ids')
  final List<String> matchGameIds;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

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
  }) {
    return GroupModel(
      id: id,
      authorId: authorId,
      createdAt: createdAt,

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
    );
  }

  Map<String, dynamic> toJson() => _$GroupModelToJson(this);
}
