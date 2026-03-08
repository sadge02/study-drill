import 'package:json_annotation/json_annotation.dart';

import '../../utils/constants/models/group/group_model_field_constants.dart';

part 'group_model.g.dart';

/// Controls who can discover and join the group.
enum GroupVisibility {
  @JsonValue(GroupModelFieldConstants.groupVisibilityPublic)
  public,
  @JsonValue(GroupModelFieldConstants.groupVisibilityPrivate)
  private,
  @JsonValue(GroupModelFieldConstants.groupVisibilityFriends)
  friends,
}

/// Configurable settings for a [GroupModel].
@JsonSerializable()
class GroupSettings {
  const GroupSettings({
    this.autoAddAsEditor = true,
    this.requiresJoinApproval = false,
  });

  factory GroupSettings.fromJson(Map<String, dynamic> json) =>
      _$GroupSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$GroupSettingsToJson(this);

  // Automatically add a new member as an editor.
  @JsonKey(name: GroupModelFieldConstants.autoAddAsEditor)
  final bool autoAddAsEditor;

  // Require admin approval to join group.
  @JsonKey(name: GroupModelFieldConstants.requiresJoinApproval)
  final bool requiresJoinApproval;

  GroupSettings copyWith({bool? autoAddAsEditor, bool? requiresJoinApproval}) {
    return GroupSettings(
      autoAddAsEditor: autoAddAsEditor ?? this.autoAddAsEditor,
      requiresJoinApproval: requiresJoinApproval ?? this.requiresJoinApproval,
    );
  }
}

/// A pending request from a user to join a [GroupModel].
@JsonSerializable()
class GroupJoinRequest {
  const GroupJoinRequest({
    required this.id,
    required this.userId,
    required this.createdAt,
  });

  factory GroupJoinRequest.fromJson(Map<String, dynamic> json) =>
      _$GroupJoinRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GroupJoinRequestToJson(this);

  // ID of the join request.
  @JsonKey(name: GroupModelFieldConstants.joinRequestId)
  final String id;

  // ID of the user requesting to join.
  @JsonKey(name: GroupModelFieldConstants.joinRequestUserId)
  final String userId;

  // Timestamp when the request was created.
  @JsonKey(name: GroupModelFieldConstants.joinRequestCreatedAt)
  final DateTime createdAt;

  GroupJoinRequest copyWith({String? id, String? userId, DateTime? createdAt}) {
    return GroupJoinRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A collection of users and content (tests, flashcards, connects).
@JsonSerializable(explicitToJson: true)
class GroupModel {
  GroupModel({
    required this.id,
    required this.authorId,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    this.description = '',
    this.profilePic = '',
    required this.visibility,
    GroupSettings? settings,
    this.tags = const [],
    this.adminIds = const [],
    this.creatorIds = const [],
    this.userIds = const [],
    this.testIds = const [],
    this.flashcardIds = const [],
    this.connectIds = const [],
    this.joinRequests = const [],
  }) : settings = settings ?? const GroupSettings();

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupModelToJson(this);

  // Group ID.
  @JsonKey(name: GroupModelFieldConstants.id)
  final String id;

  // User ID of the group author.
  @JsonKey(name: GroupModelFieldConstants.authorId)
  final String authorId;

  // Timestamps for group creation.
  @JsonKey(name: GroupModelFieldConstants.createdAt)
  final DateTime createdAt;

  // Timestamps for last group update.
  @JsonKey(name: GroupModelFieldConstants.updatedAt)
  final DateTime updatedAt;

  // Group title.
  @JsonKey(name: GroupModelFieldConstants.title)
  final String title;

  // Group description.
  @JsonKey(name: GroupModelFieldConstants.description)
  final String description;

  // URL or path to the group's profile picture.
  @JsonKey(name: GroupModelFieldConstants.profilePic)
  final String profilePic;

  // Group visibility setting.
  @JsonKey(name: GroupModelFieldConstants.visibility)
  final GroupVisibility visibility;

  // Configurable group settings.
  @JsonKey(name: GroupModelFieldConstants.settings)
  final GroupSettings settings;

  // Tags for filtering and discovery.
  @JsonKey(name: GroupModelFieldConstants.tags)
  final List<String> tags;

  // List of user IDs who are admins of the group.
  @JsonKey(name: GroupModelFieldConstants.adminIds)
  final List<String> adminIds;

  // List of user IDs who are creators of content in the group.
  @JsonKey(name: GroupModelFieldConstants.creatorIds)
  final List<String> creatorIds;

  // List of user IDs who are members of the group.
  @JsonKey(name: GroupModelFieldConstants.userIds)
  final List<String> userIds;

  // List of test IDs associated with the group.
  @JsonKey(name: GroupModelFieldConstants.testIds)
  final List<String> testIds;

  // List of flashcard set IDs associated with the group.
  @JsonKey(name: GroupModelFieldConstants.flashcardIds)
  final List<String> flashcardIds;

  // List of connect IDs associated with the group.
  @JsonKey(name: GroupModelFieldConstants.connectIds)
  final List<String> connectIds;

  // List of pending join requests for the group.
  @JsonKey(name: GroupModelFieldConstants.joinRequests)
  final List<GroupJoinRequest> joinRequests;

  /// Total number of members in the group.
  int get memberCount => userIds.length;

  /// Number of pending join requests.
  int get joinRequestCount => joinRequests.length;

  /// Total number of content items (tests + flashcards + connects).
  int get totalContentCount =>
      testIds.length + flashcardIds.length + connectIds.length;

  /// Total number of tests in the group.
  int get testCount => testIds.length;

  /// Total number of flashcard sets in the group.
  int get flashcardCount => flashcardIds.length;

  /// Total number of connects in the group.
  int get connectCount => connectIds.length;

  /// Whether new members are automatically added as editors.
  bool get autoAddAsEditor => settings.autoAddAsEditor;

  /// Whether this group is publicly visible.
  bool get isPublic => visibility == GroupVisibility.public;

  /// Whether this group is private and not discoverable.
  bool get isPrivate => visibility == GroupVisibility.private;

  /// Whether this group is only visible to friends of member.
  bool get isFriendsOnly => visibility == GroupVisibility.friends;

  /// Whether the given user is an admin of this group.
  bool isAdmin(String id) => adminIds.contains(id);

  /// Whether the given user is an editor of this group.
  bool isCreator(String id) => creatorIds.contains(id);

  /// Whether the given user is a member of this group.
  bool isMember(String id) => userIds.contains(id);

  bool isVisibleToUser(String userId, List<String> userFriendIds) {
    if (isPublic) {
      return true;
    }

    if (isPrivate) {
      return isMember(userId);
    }

    if (isFriendsOnly) {
      return isMember(userId) ||
          userFriendIds.any((friendId) => isMember(friendId));
    }
    return false;
  }

  GroupModel copyWith({
    String? title,
    String? description,
    String? profilePic,
    GroupVisibility? visibility,
    GroupSettings? settings,
    List<String>? tags,
    List<String>? adminIds,
    List<String>? creatorIds,
    List<String>? userIds,
    List<String>? testIds,
    List<String>? flashcardIds,
    List<String>? connectIds,
    List<GroupJoinRequest>? joinRequests,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id,
      authorId: authorId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      profilePic: profilePic ?? this.profilePic,
      visibility: visibility ?? this.visibility,
      settings: settings ?? this.settings,
      tags: tags ?? this.tags,
      adminIds: adminIds ?? this.adminIds,
      creatorIds: creatorIds ?? this.creatorIds,
      userIds: userIds ?? this.userIds,
      testIds: testIds ?? this.testIds,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      connectIds: connectIds ?? this.connectIds,
      joinRequests: joinRequests ?? this.joinRequests,
    );
  }
}
