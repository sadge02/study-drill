import 'package:json_annotation/json_annotation.dart';

import '../../utils/constants/models/test/test_model_field_constants.dart';

part 'test_model.g.dart';

/// Defines the type of a test question, either single choice or multiple choice.
enum QuestionType {
  @JsonValue(TestModelFieldConstants.singleChoice)
  singleChoice,
  @JsonValue(TestModelFieldConstants.multipleChoice)
  multipleChoice,
  @JsonValue(TestModelFieldConstants.trueFalse)
  trueFalse,
  @JsonValue(TestModelFieldConstants.fillIntheBlank)
  fillInTheBlank,
  @JsonValue(TestModelFieldConstants.ordering)
  ordering,
}

/// A single answer choice within a [TestQuestion].
///
/// [isCorrect] may be true on more than one answer per question — see
/// [TestQuestion.isMultipleChoice].
@JsonSerializable()
class TestAnswerOption {
  const TestAnswerOption({
    required this.id,
    required this.answerText,
    required this.isCorrect,
  });

  factory TestAnswerOption.fromJson(Map<String, dynamic> json) =>
      _$TestAnswerOptionFromJson(json);

  Map<String, dynamic> toJson() => _$TestAnswerOptionToJson(this);

  // Answer ID
  @JsonKey(name: TestModelFieldConstants.answerId)
  final String id;

  // Answer text
  @JsonKey(name: TestModelFieldConstants.answerText)
  final String answerText;

  // Whether this answer is marked correct
  @JsonKey(name: TestModelFieldConstants.answerIsCorrect)
  final bool isCorrect;

  TestAnswerOption copyWith({String? id, String? answerText, bool? isCorrect}) {
    return TestAnswerOption(
      id: id ?? this.id,
      answerText: answerText ?? this.answerText,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

/// A single question within a [TestModel].
///
/// A question contains a list of [TestAnswerOption]s.
@JsonSerializable(explicitToJson: true)
class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.question,
    required this.answers,
    required this.questionType,
  });

  factory TestQuestion.fromJson(Map<String, dynamic> json) =>
      _$TestQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$TestQuestionToJson(this);

  // ID of the question.
  @JsonKey(name: TestModelFieldConstants.questionId)
  final String id;

  // The question text.
  @JsonKey(name: TestModelFieldConstants.questionText)
  final String question;

  // Answers to the question.
  @JsonKey(name: TestModelFieldConstants.questionAnswers)
  final List<TestAnswerOption> answers;

  // One or multiple choice answer question.
  @JsonKey(name: TestModelFieldConstants.questionType)
  final QuestionType questionType;

  /// IDs of all answer options that are marked correct.
  List<String> get correctAnswerIds => answers
      .where((answer) => answer.isCorrect)
      .map((answer) => answer.id)
      .toList();

  /// IDs of all answer options that are marked incorrect.
  List<String> getIncorrectAnswerIds() => answers
      .where((answer) => !answer.isCorrect)
      .map((answer) => answer.id)
      .toList();

  /// Type of question.
  QuestionType get getQuestionType => questionType;

  /// True if this question has more than one correct answer.
  bool get isMultipleChoice => questionType == QuestionType.multipleChoice;

  /// True if this question has exactly one correct answer.
  bool get isSingleChoice => questionType == QuestionType.singleChoice;

  /// Number of correct answers for this question.
  int get correctCount => answers.where((answer) => answer.isCorrect).length;

  /// Number of incorrect answers for this question.
  int get incorrectCount => answers.where((answer) => !answer.isCorrect).length;

  TestQuestion copyWith({
    String? id,
    String? question,
    List<TestAnswerOption>? answers,
    String? explanation,
    QuestionType? questionType,
  }) {
    return TestQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      answers: answers ?? this.answers,
      questionType: questionType ?? this.questionType,
    );
  }
}

/// A single recorded attempt at a [TestModel] by a user.
@JsonSerializable()
class TestAttempt {
  const TestAttempt({
    required this.id,
    required this.userId,
    required this.correctQuestionIds,
    required this.incorrectQuestionIds,
    required this.completedAt,
  });

  factory TestAttempt.fromJson(Map<String, dynamic> json) =>
      _$TestAttemptFromJson(json);

  Map<String, dynamic> toJson() => _$TestAttemptToJson(this);

  // ID of the attempt.
  @JsonKey(name: TestModelFieldConstants.attemptId)
  final String id;

  // ID of the user who took the test.
  @JsonKey(name: TestModelFieldConstants.attemptUserId)
  final String userId;

  // List of question IDs the user answered correctly.
  @JsonKey(name: TestModelFieldConstants.attemptCorrectQuestionIds)
  final List<String> correctQuestionIds;

  // List of question IDs the user answered incorrectly.
  @JsonKey(name: TestModelFieldConstants.attemptIncorrectQuestionIds)
  final List<String> incorrectQuestionIds;

  // Timestamp when the attempt was completed.
  @JsonKey(name: TestModelFieldConstants.attemptCompletedAt)
  final DateTime completedAt;

  /// Number of correct answers.
  int get correct => correctQuestionIds.length;

  /// Number of incorrect answers.
  int get incorrect => incorrectQuestionIds.length;

  /// Total number of questions attempted.
  int get total => correct + incorrect;

  /// Accuracy percentage (0–100). Returns 0 when no answers were given.
  double get answerAccuracy => total == 0 ? 0.0 : (correct / total) * 100;

  TestAttempt copyWith({
    String? id,
    String? userId,
    List<String>? correctQuestionIds,
    List<String>? incorrectQuestionIds,
    DateTime? completedAt,
  }) {
    return TestAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      correctQuestionIds: correctQuestionIds ?? this.correctQuestionIds,
      incorrectQuestionIds: incorrectQuestionIds ?? this.incorrectQuestionIds,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Represents a test consisting of an list of [TestQuestion]s.
///
/// Each question contains N answer options with one or more marked correct.
@JsonSerializable(explicitToJson: true)
class TestModel {
  TestModel({
    required this.id,
    required this.authorId,
    required this.groupId,
    required this.title,
    this.description = '',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.timeLimit,
    this.questions = const [],
    this.attempts = const [],
  });

  factory TestModel.fromJson(Map<String, dynamic> json) =>
      _$TestModelFromJson(json);

  Map<String, dynamic> toJson() => _$TestModelToJson(this);

  // ID of the test.
  @JsonKey(name: TestModelFieldConstants.id)
  final String id;

  // ID of the author user.
  @JsonKey(name: TestModelFieldConstants.authorId)
  final String authorId;

  // ID of the group.
  @JsonKey(name: TestModelFieldConstants.groupId)
  final String? groupId;

  // Title of the test.
  @JsonKey(name: TestModelFieldConstants.title)
  final String title;

  // Short description of what the test covers.
  @JsonKey(name: TestModelFieldConstants.description)
  final String description;

  // Tags for filtering and discovery.
  @JsonKey(name: TestModelFieldConstants.tags)
  final List<String> tags;

  // Timestamp when this test was created.
  @JsonKey(name: TestModelFieldConstants.createdAt)
  final DateTime createdAt;

  // Timestamp when this test was last modified.
  @JsonKey(name: TestModelFieldConstants.updatedAt)
  final DateTime updatedAt;

  // Optional time limit in seconds.
  @JsonKey(name: TestModelFieldConstants.timeLimit)
  final int? timeLimit;

  // List of questions in this test.
  @JsonKey(name: TestModelFieldConstants.questions)
  final List<TestQuestion> questions;

  // All recorded attempts for this test from all users.
  @JsonKey(name: TestModelFieldConstants.attempts)
  final List<TestAttempt> attempts;

  /// Total number of questions in this test.
  int get questionCount => questions.length;

  /// True if this test has a time limit.
  bool get isTimed => timeLimit != null;

  /// Total number of times this test has been taken.
  int get attemptCount => attempts.length;

  /// Average accuracy percentage across all attempts (0–100).
  double get averageAccuracy {
    if (attempts.isEmpty) {
      return 0.0;
    }
    return attempts.fold(0.0, (sum, attempt) => sum + attempt.answerAccuracy) /
        attempts.length;
  }

  /// All attempts for a specific user, ordered most-recent first.
  List<TestAttempt> attemptsForUser(String userId) =>
      attempts.where((attempt) => attempt.userId == userId).toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  TestModel copyWith({
    String? title,
    String? description,
    List<String>? tags,
    DateTime? updatedAt,
    int? timeLimit,
    List<TestQuestion>? questions,
    List<TestAttempt>? attempts,
  }) {
    return TestModel(
      id: id,
      authorId: authorId,
      groupId: groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeLimit: timeLimit ?? this.timeLimit,
      questions: questions ?? this.questions,
      attempts: attempts ?? this.attempts,
    );
  }
}
