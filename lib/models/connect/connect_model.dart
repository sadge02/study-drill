import 'package:json_annotation/json_annotation.dart';

import '../../utils/constants/models/connect/connect_model_field_constants.dart';

part 'connect_model.g.dart';

/// A single question-answer pair within a [ConnectModel].
///
/// The user is shown all [question] values and all [answer] values in
/// shuffled columns and must connect each question to its correct answer.
@JsonSerializable()
class ConnectPair {
  const ConnectPair({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory ConnectPair.fromJson(Map<String, dynamic> json) =>
      _$ConnectPairFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectPairToJson(this);

  /// Unique identifier for the question answer pair
  @JsonKey(name: ConnectModelFieldConstants.pairId)
  final String id;

  /// The question
  @JsonKey(name: ConnectModelFieldConstants.pairQuestion)
  final String question;

  /// The correct answer to the question
  @JsonKey(name: ConnectModelFieldConstants.pairAnswer)
  final String answer;

  ConnectPair copyWith({String? id, String? question, String? answer}) {
    return ConnectPair(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
    );
  }
}

/// A single recorded attempt at a [ConnectModel] by a user.
@JsonSerializable()
class ConnectAttempt {
  const ConnectAttempt({
    required this.id,
    required this.userId,
    required this.completedAt,
    this.correctPairIds = const [],
    this.incorrectPairIds = const [],
  });

  factory ConnectAttempt.fromJson(Map<String, dynamic> json) =>
      _$ConnectAttemptFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectAttemptToJson(this);

  // ID of the attempt.
  @JsonKey(name: ConnectModelFieldConstants.attemptId)
  final String id;

  // ID of the user who took the connect.
  @JsonKey(name: ConnectModelFieldConstants.attemptUserId)
  final String userId;

  // Timestamp when the attempt was completed.
  @JsonKey(name: ConnectModelFieldConstants.attemptCompletedAt)
  final DateTime completedAt;

  // List of pair IDs the user matched correctly.
  @JsonKey(name: ConnectModelFieldConstants.attemptCorrectPairIds)
  final List<String> correctPairIds;

  // List of pair IDs the user matched incorrectly.
  @JsonKey(name: ConnectModelFieldConstants.attemptIncorrectPairIds)
  final List<String> incorrectPairIds;

  // Number of correct pairs in this attempt.
  int get correct => correctPairIds.length;

  // Number of incorrect pairs in this attempt.
  int get incorrect => incorrectPairIds.length;

  /// Total number of pairs attempted.
  int get total => correct + incorrect;

  /// Accuracy percentage (0–100). Returns 0 when no pairs were attempted.
  double get accuracy => total == 0 ? 0.0 : (correct / total) * 100;

  ConnectAttempt copyWith({
    String? id,
    String? userId,
    DateTime? completedAt,
    List<String>? correctPairIds,
    List<String>? incorrectPairIds,
  }) {
    return ConnectAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      correctPairIds: correctPairIds ?? this.correctPairIds,
      incorrectPairIds: incorrectPairIds ?? this.incorrectPairIds,
    );
  }
}

/// A connect game consisting of an ordered list of [ConnectPair]s.
///
/// During play both sides of every pair are displayed in separate shuffled
/// columns and the user drags or taps to connect each question to its
/// correct answer.
@JsonSerializable(explicitToJson: true)
class ConnectModel {
  ConnectModel({
    required this.id,
    required this.authorId,
    required this.groupId,
    required this.title,
    this.description = '',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.timeLimit,
    this.pairs = const [],
    this.attempts = const [],
  });

  factory ConnectModel.fromJson(Map<String, dynamic> json) =>
      _$ConnectModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectModelToJson(this);

  /// Unique Identifier for the connect game
  @JsonKey(name: ConnectModelFieldConstants.id)
  final String id;

  /// Unique identifier of the author user
  @JsonKey(name: ConnectModelFieldConstants.authorId)
  final String authorId;

  /// Unique identifier of the group this connect belongs to
  @JsonKey(name: ConnectModelFieldConstants.groupId)
  final String groupId;

  /// Title of the connect game
  @JsonKey(name: ConnectModelFieldConstants.title)
  final String title;

  /// Short description of what this connect game covers
  @JsonKey(name: ConnectModelFieldConstants.description)
  final String description;

  /// Tags for filtering and discovery
  @JsonKey(name: ConnectModelFieldConstants.tags)
  final List<String> tags;

  /// Timestamp when this connect was created
  @JsonKey(name: ConnectModelFieldConstants.createdAt)
  final DateTime createdAt;

  /// Timestamp when this connect was last modified
  @JsonKey(name: ConnectModelFieldConstants.updatedAt)
  final DateTime updatedAt;

  /// Optional time limit in seconds
  @JsonKey(name: ConnectModelFieldConstants.timeLimit)
  final int? timeLimit;

  /// List of pairs in this connect game
  @JsonKey(name: ConnectModelFieldConstants.pairs)
  final List<ConnectPair> pairs;

  // All recorded attempts for this connect from all users.
  @JsonKey(name: ConnectModelFieldConstants.attempts)
  final List<ConnectAttempt> attempts;

  /// Total number of pairs in this connect game.
  int get pairCount => pairs.length;

  /// True if this connect has a time limit.
  bool get hasTimeLimit => timeLimit != null;

  /// Total number of times this connect has been taken.
  int get attemptCount => attempts.length;

  /// Average accuracy percentage across all attempts (0–100).
  double get averageAccuracy {
    if (attempts.isEmpty) {
      return 0.0;
    }
    return attempts.fold(0.0, (sum, a) => sum + a.accuracy) / attempts.length;
  }

  /// All attempts for a specific user, ordered most-recent first.
  List<ConnectAttempt> attemptsForUser(String userId) =>
      attempts.where((attempt) => attempt.userId == userId).toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  int get numberOfScreens =>
      (pairCount / ConnectModelFieldConstants.maxPairsPerScreen).ceil();

  List<int> get questionDistribution {
    final int pairs = pairCount;

    if (pairs <= ConnectModelFieldConstants.maxPairsPerScreen) {
      return [pairs];
    }

    int screens = numberOfScreens;

    while (pairs / screens < ConnectModelFieldConstants.minPairsPerScreen) {
      screens--;
    }

    final int base = pairs ~/ screens;
    final int remainder = pairs % screens;

    final List<int> result = [];

    for (int i = 0; i < screens; ++i) {
      result.add(base + (i < remainder ? 1 : 0));
    }

    return result;
  }

  ConnectModel copyWith({
    String? title,
    String? description,
    List<String>? tags,
    DateTime? updatedAt,
    int? timeLimit,
    List<ConnectPair>? pairs,
    List<ConnectAttempt>? attempts,
  }) {
    return ConnectModel(
      id: id,
      authorId: authorId,
      groupId: groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeLimit: timeLimit ?? this.timeLimit,
      pairs: pairs ?? this.pairs,
      attempts: attempts ?? this.attempts,
    );
  }
}
