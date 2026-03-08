// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestAnswerOption _$TestAnswerOptionFromJson(Map<String, dynamic> json) =>
    TestAnswerOption(
      id: json['id'] as String,
      answerText: json['answer_text'] as String,
      isCorrect: json['is_correct'] as bool,
    );

Map<String, dynamic> _$TestAnswerOptionToJson(TestAnswerOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'answer_text': instance.answerText,
      'is_correct': instance.isCorrect,
    };

TestQuestion _$TestQuestionFromJson(Map<String, dynamic> json) => TestQuestion(
  id: json['id'] as String,
  question: json['question_text'] as String,
  answers: (json['answers'] as List<dynamic>)
      .map((e) => TestAnswerOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
);

Map<String, dynamic> _$TestQuestionToJson(TestQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question_text': instance.question,
      'answers': instance.answers.map((e) => e.toJson()).toList(),
      'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
    };

const _$QuestionTypeEnumMap = {
  QuestionType.singleChoice: 'single_choice',
  QuestionType.multipleChoice: 'multiple_choice',
  QuestionType.trueFalse: 'true_false',
  QuestionType.fillInTheBlank: 'fill_in_the_blank',
  QuestionType.ordering: 'ordering',
};

TestAttempt _$TestAttemptFromJson(Map<String, dynamic> json) => TestAttempt(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  correctQuestionIds: (json['correct_question_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  incorrectQuestionIds: (json['incorrect_question_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  completedAt: DateTime.parse(json['completed_at'] as String),
);

Map<String, dynamic> _$TestAttemptToJson(TestAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'correct_question_ids': instance.correctQuestionIds,
      'incorrect_question_ids': instance.incorrectQuestionIds,
      'completed_at': instance.completedAt.toIso8601String(),
    };

TestModel _$TestModelFromJson(Map<String, dynamic> json) => TestModel(
  id: json['id'] as String,
  authorId: json['author_id'] as String,
  groupId: json['group_id'] as String?,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  timeLimit: (json['time_limit'] as num?)?.toInt(),
  questions:
      (json['questions'] as List<dynamic>?)
          ?.map((e) => TestQuestion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  attempts:
      (json['attempts'] as List<dynamic>?)
          ?.map((e) => TestAttempt.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$TestModelToJson(TestModel instance) => <String, dynamic>{
  'id': instance.id,
  'author_id': instance.authorId,
  'group_id': instance.groupId,
  'title': instance.title,
  'description': instance.description,
  'tags': instance.tags,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'time_limit': instance.timeLimit,
  'questions': instance.questions.map((e) => e.toJson()).toList(),
  'attempts': instance.attempts.map((e) => e.toJson()).toList(),
};
