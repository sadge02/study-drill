import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/flashcard/flashcard_model.dart';
import '../../utils/constants/collections/database_constants.dart';
import '../../utils/constants/models/flashcard/flashcard_model_field_constants.dart';
import '../../utils/enums/flashcard/flashcard_sort_option_enum.dart';
import '../group/group_service.dart';

class FlashcardService {
  final GroupService _groupService = GroupService();

  final CollectionReference<Map<String, dynamic>> _flashcardCollection =
      FirebaseFirestore.instance.collection(
        DatabaseConstants.flashcardsCollection,
      );

  /// --------------------------------------------------------------------------
  /// CREATE
  /// --------------------------------------------------------------------------

  /// Creates a new flashcard set document in Firestore and registers it on the
  /// group.
  Future<void> createFlashcardSet(FlashcardSet flashcardSet) async {
    await _flashcardCollection.doc(flashcardSet.id).set(flashcardSet.toJson());
    await _groupService.addContentId(
      flashcardSet.groupId,
      flashcardId: flashcardSet.id,
    );
  }

  /// --------------------------------------------------------------------------
  /// READ
  /// --------------------------------------------------------------------------

  /// Fetches a single flashcard set by its [flashcardSetId].
  Future<FlashcardSet?> getFlashcardSetById(String flashcardSetId) async {
    final document = await _flashcardCollection.doc(flashcardSetId).get();
    if (!document.exists || document.data() == null) {
      return null;
    }
    return FlashcardSet.fromJson(document.data()!);
  }

  /// Returns a real-time stream of a single flashcard set.
  Stream<FlashcardSet?> streamFlashcardSetById(String flashcardSetId) {
    return _flashcardCollection.doc(flashcardSetId).snapshots().map((document) {
      if (!document.exists || document.data() == null) {
        return null;
      }
      return FlashcardSet.fromJson(document.data()!);
    });
  }

  /// Fetches all flashcard sets belonging to a specific group.
  Future<List<FlashcardSet>> getFlashcardSetsByGroupId(String groupId) async {
    final snapshot = await _flashcardCollection
        .where(FlashcardModelFieldConstants.groupId, isEqualTo: groupId)
        .get();
    return snapshot.docs
        .map((document) => FlashcardSet.fromJson(document.data()))
        .toList();
  }

  /// Returns a real-time stream of all flashcard sets in a group.
  Stream<List<FlashcardSet>> streamFlashcardSetsByGroupId(String groupId) {
    return _flashcardCollection
        .where(FlashcardModelFieldConstants.groupId, isEqualTo: groupId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => FlashcardSet.fromJson(document.data()))
              .toList(),
        );
  }

  /// Fetches all flashcard sets created by a specific user.
  Future<List<FlashcardSet>> getFlashcardSetsByAuthorId(String authorId) async {
    final snapshot = await _flashcardCollection
        .where(FlashcardModelFieldConstants.authorId, isEqualTo: authorId)
        .get();
    return snapshot.docs
        .map((document) => FlashcardSet.fromJson(document.data()))
        .toList();
  }

  /// --------------------------------------------------------------------------
  /// UPDATE
  /// --------------------------------------------------------------------------

  /// Updates a flashcard set document with the provided [FlashcardSet].
  Future<void> updateFlashcardSet(FlashcardSet flashcardSet) async {
    await _flashcardCollection.doc(flashcardSet.id).set(flashcardSet.toJson());
  }

  /// --------------------------------------------------------------------------
  /// DELETE
  /// --------------------------------------------------------------------------

  /// Deletes a flashcard set document from Firestore and removes its ID from
  /// the group.
  Future<void> deleteFlashcardSet(String flashcardSetId) async {
    final flashcardSet = await getFlashcardSetById(flashcardSetId);
    await _flashcardCollection.doc(flashcardSetId).delete();

    if (flashcardSet != null) {
      await _groupService.removeContentId(
        flashcardSet.groupId,
        flashcardId: flashcardSet.id,
      );
    }
  }

  /// --------------------------------------------------------------------------
  /// FILTERING & SORTING
  /// --------------------------------------------------------------------------

  /// Fetches all flashcard sets for a group and applies optional filters and
  /// sorting.
  ///
  /// - [titleStartsWith]: keeps only sets whose title starts with this
  ///   string (case-insensitive).
  /// - [tags]: keeps only sets that contain **all** of the provided tags.
  /// - [sortOption]: determines the sort order of the returned list.
  Future<List<FlashcardSet>> getFilteredFlashcardSetsByGroupId(
    String groupId, {
    String? titleStartsWith,
    List<String>? tags,
    FlashcardSortOption sortOption = FlashcardSortOption.newest,
  }) async {
    List<FlashcardSet> sets = await getFlashcardSetsByGroupId(groupId);

    sets = _filterByTitle(sets, titleStartsWith);
    sets = _filterByTags(sets, tags);
    sets = _sortFlashcardSets(sets, sortOption);

    return sets;
  }

  /// Returns a real-time stream of flashcard sets for a group with optional
  /// filters and sorting applied.
  Stream<List<FlashcardSet>> streamFilteredFlashcardSetsByGroupId(
    String groupId, {
    String? titleStartsWith,
    List<String>? tags,
    FlashcardSortOption sortOption = FlashcardSortOption.newest,
  }) {
    return streamFlashcardSetsByGroupId(groupId).map((sets) {
      List<FlashcardSet> result = sets;

      result = _filterByTitle(result, titleStartsWith);
      result = _filterByTags(result, tags);
      result = _sortFlashcardSets(result, sortOption);

      return result;
    });
  }

  /// Filters flashcard sets whose title starts with [prefix]
  /// (case-insensitive).
  List<FlashcardSet> _filterByTitle(List<FlashcardSet> sets, String? prefix) {
    if (prefix == null || prefix.isEmpty) {
      return sets;
    }

    final lowerPrefix = prefix.toLowerCase();

    return sets
        .where((s) => s.title.toLowerCase().startsWith(lowerPrefix))
        .toList();
  }

  /// Filters flashcard sets that contain **all** of the provided [tags].
  List<FlashcardSet> _filterByTags(
    List<FlashcardSet> sets,
    List<String>? tags,
  ) {
    if (tags == null || tags.isEmpty) {
      return sets;
    }

    final lowerTags = tags.map((t) => t.toLowerCase()).toSet();

    return sets.where((s) {
      final setTags = s.tags.map((t) => t.toLowerCase()).toSet();
      return setTags.containsAll(lowerTags);
    }).toList();
  }

  /// Sorts a list of flashcard sets according to the given [sortOption].
  List<FlashcardSet> _sortFlashcardSets(
    List<FlashcardSet> sets,
    FlashcardSortOption sortOption,
  ) {
    switch (sortOption) {
      case FlashcardSortOption.mostAttempts:
        sets.sort((a, b) => b.attemptCount.compareTo(a.attemptCount));
      case FlashcardSortOption.fewestAttempts:
        sets.sort((a, b) => a.attemptCount.compareTo(b.attemptCount));
      case FlashcardSortOption.mostCards:
        sets.sort((a, b) => b.cardCount.compareTo(a.cardCount));
      case FlashcardSortOption.fewestCards:
        sets.sort((a, b) => a.cardCount.compareTo(b.cardCount));
      case FlashcardSortOption.newest:
        sets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case FlashcardSortOption.oldest:
        sets.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case FlashcardSortOption.alphabetical:
        sets.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return sets;
  }

  /// --------------------------------------------------------------------------
  /// ATTEMPT MANAGEMENT
  /// --------------------------------------------------------------------------

  /// Records a new attempt for the flashcard set.
  Future<void> addAttempt(
    String flashcardSetId,
    FlashcardAttempt attempt,
  ) async {
    await _flashcardCollection.doc(flashcardSetId).update({
      FlashcardModelFieldConstants.attempts: FieldValue.arrayUnion([
        attempt.toJson(),
      ]),
    });
  }
}
