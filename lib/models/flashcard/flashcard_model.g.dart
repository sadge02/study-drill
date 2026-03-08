// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Flashcard _$FlashcardFromJson(Map<String, dynamic> json) => Flashcard(
  id: json['id'] as String,
  question: json['question'] as String,
  answer: json['answer'] as String,
);

Map<String, dynamic> _$FlashcardToJson(Flashcard instance) => <String, dynamic>{
  'id': instance.id,
  'question': instance.question,
  'answer': instance.answer,
};

FlashcardAttempt _$FlashcardAttemptFromJson(Map<String, dynamic> json) =>
    FlashcardAttempt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      correctCardIds: (json['correct_card_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      incorrectCardIds: (json['incorrect_card_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      completedAt: DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$FlashcardAttemptToJson(FlashcardAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'correct_card_ids': instance.correctCardIds,
      'incorrect_card_ids': instance.incorrectCardIds,
      'completed_at': instance.completedAt.toIso8601String(),
    };

FlashcardSet _$FlashcardSetFromJson(Map<String, dynamic> json) => FlashcardSet(
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
  cards:
      (json['cards'] as List<dynamic>?)
          ?.map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  attempts:
      (json['attempts'] as List<dynamic>?)
          ?.map((e) => FlashcardAttempt.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$FlashcardSetToJson(FlashcardSet instance) =>
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
      'cards': instance.cards.map((e) => e.toJson()).toList(),
      'attempts': instance.attempts.map((e) => e.toJson()).toList(),
    };
