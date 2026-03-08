// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectPair _$ConnectPairFromJson(Map<String, dynamic> json) => ConnectPair(
  id: json['id'] as String,
  question: json['question'] as String,
  answer: json['answer'] as String,
);

Map<String, dynamic> _$ConnectPairToJson(ConnectPair instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question': instance.question,
      'answer': instance.answer,
    };

ConnectAttempt _$ConnectAttemptFromJson(Map<String, dynamic> json) =>
    ConnectAttempt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      correctPairIds:
          (json['correct_pair_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      incorrectPairIds:
          (json['incorrect_pair_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ConnectAttemptToJson(ConnectAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'completed_at': instance.completedAt.toIso8601String(),
      'correct_pair_ids': instance.correctPairIds,
      'incorrect_pair_ids': instance.incorrectPairIds,
    };

ConnectModel _$ConnectModelFromJson(Map<String, dynamic> json) => ConnectModel(
  id: json['id'] as String,
  authorId: json['author_id'] as String,
  groupId: json['group_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  timeLimit: (json['time_limit'] as num?)?.toInt(),
  pairs:
      (json['pairs'] as List<dynamic>?)
          ?.map((e) => ConnectPair.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  attempts:
      (json['attempts'] as List<dynamic>?)
          ?.map((e) => ConnectAttempt.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ConnectModelToJson(ConnectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'group_id': instance.groupId,
      'title': instance.title,
      'description': instance.description,
      'tags': instance.tags,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'time_limit': instance.timeLimit,
      'pairs': instance.pairs.map((e) => e.toJson()).toList(),
      'attempts': instance.attempts.map((e) => e.toJson()).toList(),
    };
