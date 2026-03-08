import 'package:json_annotation/json_annotation.dart';

import '../../utils/constants/models/flashcard/flashcard_model_field_constants.dart';

part 'flashcard_model.g.dart';

/// A single card within a [FlashcardSet].
///
/// Each card has a [question] and an [answer]. The user self-evaluates by
/// pressing correct or incorrect after seeing the answer.
@JsonSerializable()
class Flashcard {
  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) =>
      _$FlashcardFromJson(json);

  Map<String, dynamic> toJson() => _$FlashcardToJson(this);

  /// Unique identifier for the question answer pair.
  @JsonKey(name: FlashcardModelFieldConstants.cardId)
  final String id;

  /// The question shown to the user.
  @JsonKey(name: FlashcardModelFieldConstants.cardQuestion)
  final String question;

  /// The correct answer for the question.
  @JsonKey(name: FlashcardModelFieldConstants.cardAnswer)
  final String answer;

  Flashcard copyWith({String? id, String? question, String? answer}) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
    );
  }
}

/// A single recorded attempt at a [FlashcardSet] by a user.
@JsonSerializable()
class FlashcardAttempt {
  const FlashcardAttempt({
    required this.id,
    required this.userId,
    required this.correctCardIds,
    required this.incorrectCardIds,
    required this.completedAt,
  });

  factory FlashcardAttempt.fromJson(Map<String, dynamic> json) =>
      _$FlashcardAttemptFromJson(json);

  Map<String, dynamic> toJson() => _$FlashcardAttemptToJson(this);

  // ID of the attempt.
  @JsonKey(name: FlashcardModelFieldConstants.attemptId)
  final String id;

  // ID of the user who took the flashcard set.
  @JsonKey(name: FlashcardModelFieldConstants.attemptUserId)
  final String userId;

  // List of card IDs the user self-reported as correct.
  @JsonKey(name: FlashcardModelFieldConstants.attemptCorrectCardIds)
  final List<String> correctCardIds;

  // List of card IDs the user self-reported as incorrect.
  @JsonKey(name: FlashcardModelFieldConstants.attemptIncorrectCardIds)
  final List<String> incorrectCardIds;

  // Timestamp when the attempt was completed.
  @JsonKey(name: FlashcardModelFieldConstants.attemptCompletedAt)
  final DateTime completedAt;

  /// Number of cards the user got correct.
  int get correct => correctCardIds.length;

  /// Number of cards the user got incorrect.
  int get incorrect => incorrectCardIds.length;

  /// Total number of cards attempted.
  int get totalCards => correct + incorrect;

  /// Accuracy percentage (0–100). Returns 0 when no cards were attempted.
  double get accuracy => totalCards == 0 ? 0.0 : (correct / totalCards) * 100;

  FlashcardAttempt copyWith({
    String? id,
    String? userId,
    List<String>? correctCardIds,
    List<String>? incorrectCardIds,
    DateTime? completedAt,
  }) {
    return FlashcardAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      correctCardIds: correctCardIds ?? this.correctCardIds,
      incorrectCardIds: incorrectCardIds ?? this.incorrectCardIds,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// A collection of [Flashcard]s.
///
/// During a session each card is shown question-side first. The user flips
/// to reveal the answer and self-reports whether they got it right.
@JsonSerializable(explicitToJson: true)
class FlashcardSet {
  FlashcardSet({
    required this.id,
    required this.authorId,
    required this.groupId,
    required this.title,
    this.description = '',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.timeLimit,
    this.cards = const [],
    this.attempts = const [],
  });

  factory FlashcardSet.fromJson(Map<String, dynamic> json) =>
      _$FlashcardSetFromJson(json);

  Map<String, dynamic> toJson() => _$FlashcardSetToJson(this);

  /// Unique identifier for the flashcard set.
  @JsonKey(name: FlashcardModelFieldConstants.id)
  final String id;

  /// Unique identifier of the author user.
  @JsonKey(name: FlashcardModelFieldConstants.authorId)
  final String authorId;

  /// Unique identifier of the group this set belongs to.
  @JsonKey(name: FlashcardModelFieldConstants.groupId)
  final String groupId;

  /// Title of the flashcard set.
  @JsonKey(name: FlashcardModelFieldConstants.title)
  final String title;

  /// Short description of what this set covers.
  @JsonKey(name: FlashcardModelFieldConstants.description)
  final String description;

  /// Tags for filtering and discovery.
  @JsonKey(name: FlashcardModelFieldConstants.tags)
  final List<String> tags;

  /// Timestamp when this set was created.
  @JsonKey(name: FlashcardModelFieldConstants.createdAt)
  final DateTime createdAt;

  /// Timestamp when this set was last modified.
  @JsonKey(name: FlashcardModelFieldConstants.updatedAt)
  final DateTime updatedAt;

  /// Optional time limit in seconds.
  @JsonKey(name: FlashcardModelFieldConstants.timeLimit)
  final int? timeLimit;

  /// List of flashcards in this set.
  @JsonKey(name: FlashcardModelFieldConstants.cards)
  final List<Flashcard> cards;

  // All recorded attempts for this flashcard set from all users.
  @JsonKey(name: FlashcardModelFieldConstants.attempts)
  final List<FlashcardAttempt> attempts;

  /// Total number of cards in this set.
  int get cardCount => cards.length;

  /// True if this set has a time limit.
  bool get hasTimeLimit => timeLimit != null;

  /// Total number of times this flashcard set has been taken.
  int get attemptCount => attempts.length;

  /// Average accuracy percentage across all attempts (0–100).
  double get averageAccuracy {
    if (attempts.isEmpty) {
      return 0.0;
    }
    return attempts.fold(0.0, (sum, a) => sum + a.accuracy) / attempts.length;
  }

  /// All attempts for a specific user, ordered most-recent first.
  List<FlashcardAttempt> attemptsForUser(String userId) =>
      attempts.where((attempt) => attempt.userId == userId).toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  FlashcardSet copyWith({
    String? title,
    String? description,
    List<String>? tags,
    DateTime? updatedAt,
    int? timeLimit,
    List<Flashcard>? cards,
    List<FlashcardAttempt>? attempts,
  }) {
    return FlashcardSet(
      id: id,
      authorId: authorId,
      groupId: groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeLimit: timeLimit ?? this.timeLimit,
      cards: cards ?? this.cards,
      attempts: attempts ?? this.attempts,
    );
  }
}
