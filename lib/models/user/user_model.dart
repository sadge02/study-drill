import 'package:json_annotation/json_annotation.dart';

import '../../utils/constants/models/user/user_model_field_constants.dart';

part 'user_model.g.dart';

/// The type of attempt that produced a statistics entry.
enum AttemtType {
  @JsonValue(UserModelFieldConstants.activityTypeTest)
  test,
  @JsonValue(UserModelFieldConstants.activityTypeFlashcard)
  flashcard,
  @JsonValue(UserModelFieldConstants.activityTypeConnect)
  connect,
}

/// The kind of request a [UserRequest] represents.
///
/// Covers four scenarios based on direction:
/// - [friendInvite] as sender → sent a friend request
/// - [friendInvite] as receiver → invited as a friend
/// - [groupInvite] as receiver → invited to a group
/// - [groupJoinRequest] as sender → sent a request to join a group
enum RequestType {
  @JsonValue(UserModelFieldConstants.requestTypeFriend)
  friendInvite,
  @JsonValue(UserModelFieldConstants.requestTypeGroupInvite)
  groupInvite,
  @JsonValue(UserModelFieldConstants.requestTypeGroupJoin)
  groupJoinRequest,
}

/// The current status of a [UserRequest].
enum RequestStatus {
  @JsonValue(UserModelFieldConstants.requestStatusPending)
  pending,
  @JsonValue(UserModelFieldConstants.requestStatusAccepted)
  accepted,
  @JsonValue(UserModelFieldConstants.requestStatusDeclined)
  declined,
}

/// A single recorded attempt at a test, flashcard set, or connect game.
@JsonSerializable()
class UserStatisticsEntry {
  const UserStatisticsEntry({
    required this.title,
    required this.activityType,
    required this.correct,
    required this.incorrect,
    required this.completedAt,
  });

  factory UserStatisticsEntry.fromJson(Map<String, dynamic> json) =>
      _$UserStatisticsEntryFromJson(json);

  Map<String, dynamic> toJson() => _$UserStatisticsEntryToJson(this);

  @JsonKey(name: UserModelFieldConstants.title)
  final String title;

  @JsonKey(name: UserModelFieldConstants.activityType)
  final AttemtType activityType;

  @JsonKey(name: UserModelFieldConstants.correct)
  final int correct;

  @JsonKey(name: UserModelFieldConstants.incorrect)
  final int incorrect;

  @JsonKey(name: UserModelFieldConstants.completedAt)
  final DateTime completedAt;

  /// Total number of questions attempted in this entry.
  int get total => correct + incorrect;

  /// Accuracy percentage.
  double get accuracy => total == 0 ? 0.0 : (correct / total) * 100;

  UserStatisticsEntry copyWith({
    String? title,
    AttemtType? activityType,
    int? correct,
    int? incorrect,
    DateTime? completedAt,
  }) {
    return UserStatisticsEntry(
      title: title ?? this.title,
      activityType: activityType ?? this.activityType,
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// A pending or sent request.
@JsonSerializable()
class UserRequest {
  const UserRequest({
    required this.id,
    required this.requestType,
    required this.fromUserId,
    required this.toUserId,
    this.groupId,
    this.status = RequestStatus.pending,
    required this.createdAt,
  });

  factory UserRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserRequestToJson(this);

  // ID of the request.
  @JsonKey(name: UserModelFieldConstants.requestId)
  final String id;

  // Type of request (friend invite, group invite, or group join request).
  @JsonKey(name: UserModelFieldConstants.requestType)
  final RequestType requestType;

  // User ID of the sender of the request.
  @JsonKey(name: UserModelFieldConstants.requestFromUserId)
  final String fromUserId;

  // User ID of the recipient of the request.
  @JsonKey(name: UserModelFieldConstants.requestToUserId)
  final String toUserId;

  // Relevant only for [RequestType.groupInvite] and [RequestType.groupJoin].
  @JsonKey(name: UserModelFieldConstants.requestGroupId)
  final String? groupId;

  // Current status of the request (pending, accepted, or declined).
  @JsonKey(name: UserModelFieldConstants.requestStatus)
  final RequestStatus status;

  // Timestamp when the request was created.
  @JsonKey(name: UserModelFieldConstants.requestCreatedAt)
  final DateTime createdAt;

  UserRequest copyWith({
    RequestType? requestType,
    String? fromUserId,
    String? toUserId,
    String? groupId,
    RequestStatus? status,
    DateTime? createdAt,
  }) {
    return UserRequest(
      id: id,
      requestType: requestType ?? this.requestType,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// User model representing a user.
@JsonSerializable(explicitToJson: true)
class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.description = '',
    this.profilePic = '',
    required this.createdAt,
    required this.updatedAt,
    this.statistics = const {},
    this.requests = const [],
    this.groupIds = const [],
    this.friendIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // ID of the user.
  @JsonKey(name: UserModelFieldConstants.id)
  final String id;

  // Email address of the user.
  @JsonKey(name: UserModelFieldConstants.email)
  final String email;

  // Username chosen by the user.
  @JsonKey(name: UserModelFieldConstants.username)
  final String username;

  // Description provided by the user in their profile.
  @JsonKey(name: UserModelFieldConstants.summary)
  final String description;

  // URL or path to the user's profile picture.
  @JsonKey(name: UserModelFieldConstants.profilePic)
  final String profilePic;

  // Timestamp when the user account was created.
  @JsonKey(name: UserModelFieldConstants.createdAt)
  final DateTime createdAt;

  // Timestamp when the user account was last updated.
  @JsonKey(name: UserModelFieldConstants.updatedAt)
  final DateTime updatedAt;

  // Statistics mapped by group ID, containing lists of attempts for each group.
  @JsonKey(name: UserModelFieldConstants.statistics)
  final Map<String, List<UserStatisticsEntry>> statistics;

  // List of requests sent or received by the user.
  @JsonKey(name: UserModelFieldConstants.requests)
  final List<UserRequest> requests;

  // List of group IDs that the user is currently a member of.
  @JsonKey(name: UserModelFieldConstants.groupIds)
  final List<String> groupIds;

  // List of user IDs that are friends with this user.
  @JsonKey(name: UserModelFieldConstants.friendIds)
  final List<String> friendIds;

  /// Total number of attempts across all groups.
  int get totalAttempts =>
      statistics.values.fold(0, (sum, entries) => sum + entries.length);

  /// Global accuracy percentage across every recorded attempt.
  double get globalAccuracy {
    int totalCorrect = 0;
    int totalAnswered = 0;

    for (final entries in statistics.values) {
      for (final entry in entries) {
        totalCorrect += entry.correct;
        totalAnswered += entry.total;
      }
    }

    return totalAnswered == 0 ? 0.0 : (totalCorrect / totalAnswered) * 100;
  }

  /// List of all statistics entries across every group.
  List<UserStatisticsEntry> get allStatistics =>
      statistics.values.expand((entries) => entries).toList();

  /// List of statistics entries for a specific group.
  List<UserStatisticsEntry> userGroupStatistics(String groupId) =>
      statistics[groupId] ?? [];

  /// List of all pending requests that have not yet been accepted or declined.
  List<UserRequest> unresolvedRequests() => [
    ...requests.where((request) => request.status == RequestStatus.pending),
    ...requests.where((request) => request.status == RequestStatus.pending),
  ];

  /// Pending friend invites received by the user.
  List<UserRequest> get pendingFriendInvites => requests
      .where(
        (request) =>
            request.status == RequestStatus.pending &&
            request.requestType == RequestType.friendInvite,
      )
      .toList();

  /// Pending group invites received by the user.
  List<UserRequest> get pendingGroupInvites => requests
      .where(
        (request) =>
            request.status == RequestStatus.pending &&
            request.requestType == RequestType.groupInvite,
      )
      .toList();

  /// Sent friend requests that are still pending.
  List<UserRequest> get sentFriendRequests => requests
      .where(
        (request) =>
            request.status == RequestStatus.pending &&
            request.requestType == RequestType.friendInvite,
      )
      .toList();

  /// Sent group join requests that are still pending.
  List<UserRequest> get sentGroupJoinRequests => requests
      .where(
        (request) =>
            request.status == RequestStatus.pending &&
            request.requestType == RequestType.groupJoinRequest,
      )
      .toList();

  UserModel copyWith({
    String? email,
    String? username,
    String? description,
    String? profilePic,
    DateTime? updatedAt,
    Map<String, List<UserStatisticsEntry>>? statistics,
    List<UserRequest>? requests,
    List<String>? groupIds,
    List<String>? friendIds,
  }) {
    return UserModel(
      id: id,
      createdAt: createdAt,
      email: email ?? this.email,
      username: username ?? this.username,
      description: description ?? this.description,
      profilePic: profilePic ?? this.profilePic,
      updatedAt: updatedAt ?? this.updatedAt,
      statistics: statistics ?? this.statistics,
      requests: requests ?? this.requests,
      groupIds: groupIds ?? this.groupIds,
      friendIds: friendIds ?? this.friendIds,
    );
  }
}
