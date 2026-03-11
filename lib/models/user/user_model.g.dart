// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStatisticsEntry _$UserStatisticsEntryFromJson(Map<String, dynamic> json) =>
    UserStatisticsEntry(
      title: json['test_name'] as String,
      activityType: $enumDecode(_$AttemtTypeEnumMap, json['activity_type']),
      correct: (json['correct'] as num).toInt(),
      incorrect: (json['incorrect'] as num).toInt(),
      completedAt: DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$UserStatisticsEntryToJson(
  UserStatisticsEntry instance,
) => <String, dynamic>{
  'test_name': instance.title,
  'activity_type': _$AttemtTypeEnumMap[instance.activityType]!,
  'correct': instance.correct,
  'incorrect': instance.incorrect,
  'completed_at': instance.completedAt.toIso8601String(),
};

const _$AttemtTypeEnumMap = {
  AttemtType.test: 'test',
  AttemtType.flashcard: 'flashcard',
  AttemtType.connect: 'connect',
};

UserRequest _$UserRequestFromJson(Map<String, dynamic> json) => UserRequest(
  id: json['id'] as String,
  requestType: $enumDecode(_$RequestTypeEnumMap, json['request_type']),
  fromUserId: json['from_user_id'] as String,
  toUserId: json['to_user_id'] as String,
  groupId: json['group_id'] as String?,
  status:
      $enumDecodeNullable(_$RequestStatusEnumMap, json['status']) ??
      RequestStatus.pending,
  createdAt: DateTime.parse(json['request_created_at'] as String),
);

Map<String, dynamic> _$UserRequestToJson(UserRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'request_type': _$RequestTypeEnumMap[instance.requestType]!,
      'from_user_id': instance.fromUserId,
      'to_user_id': instance.toUserId,
      'group_id': instance.groupId,
      'status': _$RequestStatusEnumMap[instance.status]!,
      'request_created_at': instance.createdAt.toIso8601String(),
    };

const _$RequestTypeEnumMap = {
  RequestType.friendInvite: 'friend',
  RequestType.groupInvite: 'group_invite',
  RequestType.groupJoinRequest: 'group_join',
};

const _$RequestStatusEnumMap = {
  RequestStatus.pending: 'pending',
  RequestStatus.accepted: 'accepted',
  RequestStatus.declined: 'declined',
};

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  username: json['username'] as String,
  description: json['summary'] as String? ?? '',
  profilePic: json['profile_pic'] as String? ?? '',
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  statistics:
      (json['statistics'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>)
              .map(
                (e) => UserStatisticsEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      ) ??
      const {},
  requests:
      (json['requests'] as List<dynamic>?)
          ?.map((e) => UserRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  groupIds:
      (json['group_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
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
  'summary': instance.description,
  'profile_pic': instance.profilePic,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'statistics': instance.statistics.map(
    (k, e) => MapEntry(k, e.map((e) => e.toJson()).toList()),
  ),
  'requests': instance.requests.map((e) => e.toJson()).toList(),
  'group_ids': instance.groupIds,
  'friend_ids': instance.friendIds,
};
