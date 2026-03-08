import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/test/test_model.dart';
import '../../utils/constants/collections/database_constants.dart';
import '../../utils/constants/models/test/test_model_field_constants.dart';
import '../../utils/enums/test/test_sort_option_enum.dart';
import '../group/group_service.dart';

class TestService {
  final GroupService _groupService = GroupService();

  final CollectionReference<Map<String, dynamic>> _testCollection =
      FirebaseFirestore.instance.collection(DatabaseConstants.testsCollection);

  /// --------------------------------------------------------------------------
  /// CREATE
  /// --------------------------------------------------------------------------

  /// Creates a new test document in Firestore and registers it on the group.
  Future<void> createTest(TestModel test) async {
    await _testCollection.doc(test.id).set(test.toJson());

    if (test.groupId != null) {
      await _groupService.addContentId(test.groupId!, testId: test.id);
    }
  }

  /// --------------------------------------------------------------------------
  /// READ
  /// --------------------------------------------------------------------------

  /// Fetches a single test by its [testId].
  Future<TestModel?> getTestById(String testId) async {
    final document = await _testCollection.doc(testId).get();
    if (!document.exists || document.data() == null) {
      return null;
    }
    return TestModel.fromJson(document.data()!);
  }

  /// Returns a real-time stream of a single test.
  Stream<TestModel?> streamTestById(String testId) {
    return _testCollection.doc(testId).snapshots().map((document) {
      if (!document.exists || document.data() == null) {
        return null;
      }
      return TestModel.fromJson(document.data()!);
    });
  }

  /// Fetches all tests belonging to a specific group.
  Future<List<TestModel>> getTestsByGroupId(String groupId) async {
    final snapshot = await _testCollection
        .where(TestModelFieldConstants.groupId, isEqualTo: groupId)
        .get();
    return snapshot.docs
        .map((document) => TestModel.fromJson(document.data()))
        .toList();
  }

  /// Returns a real-time stream of all tests in a group.
  Stream<List<TestModel>> streamTestsByGroupId(String groupId) {
    return _testCollection
        .where(TestModelFieldConstants.groupId, isEqualTo: groupId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => TestModel.fromJson(document.data()))
              .toList(),
        );
  }

  /// Fetches all tests created by a specific user.
  Future<List<TestModel>> getTestsByAuthorId(String authorId) async {
    final snapshot = await _testCollection
        .where(TestModelFieldConstants.authorId, isEqualTo: authorId)
        .get();
    return snapshot.docs
        .map((document) => TestModel.fromJson(document.data()))
        .toList();
  }

  /// --------------------------------------------------------------------------
  /// UPDATE
  /// --------------------------------------------------------------------------

  /// Updates a test document with the provided [TestModel].
  Future<void> updateTest(TestModel test) async {
    await _testCollection.doc(test.id).set(test.toJson());
  }

  /// --------------------------------------------------------------------------
  /// DELETE
  /// --------------------------------------------------------------------------

  /// Deletes a test document from Firestore and removes its ID from the group.
  Future<void> deleteTest(String testId) async {
    final test = await getTestById(testId);
    await _testCollection.doc(testId).delete();

    if (test?.groupId != null) {
      await _groupService.removeContentId(test!.groupId!, testId: test.id);
    }
  }

  /// --------------------------------------------------------------------------
  /// FILTERING & SORTING
  /// --------------------------------------------------------------------------

  /// Fetches all tests for a group and applies optional filters and sorting.
  ///
  /// - [titleStartsWith]: keeps only tests whose title starts with this
  ///   string (case-insensitive).
  /// - [tags]: keeps only tests that contain **all** of the provided tags.
  /// - [sortOption]: determines the sort order of the returned list.
  Future<List<TestModel>> getFilteredTestsByGroupId(
    String groupId, {
    String? titleStartsWith,
    List<String>? tags,
    TestSortOption sortOption = TestSortOption.newest,
  }) async {
    List<TestModel> tests = await getTestsByGroupId(groupId);

    tests = _filterByTitle(tests, titleStartsWith);
    tests = _filterByTags(tests, tags);
    tests = _sortTests(tests, sortOption);

    return tests;
  }

  /// Returns a real-time stream of tests for a group with optional filters
  /// and sorting applied.
  Stream<List<TestModel>> streamFilteredTestsByGroupId(
    String groupId, {
    String? titleStartsWith,
    List<String>? tags,
    TestSortOption sortOption = TestSortOption.newest,
  }) {
    return streamTestsByGroupId(groupId).map((tests) {
      List<TestModel> result = tests;

      result = _filterByTitle(result, titleStartsWith);
      result = _filterByTags(result, tags);
      result = _sortTests(result, sortOption);

      return result;
    });
  }

  /// Filters tests whose title starts with [prefix] (case-insensitive).
  List<TestModel> _filterByTitle(List<TestModel> tests, String? prefix) {
    if (prefix == null || prefix.isEmpty) {
      return tests;
    }

    final lowerPrefix = prefix.toLowerCase();

    return tests
        .where((t) => t.title.toLowerCase().startsWith(lowerPrefix))
        .toList();
  }

  /// Filters tests that contain **all** of the provided [tags].
  List<TestModel> _filterByTags(List<TestModel> tests, List<String>? tags) {
    if (tags == null || tags.isEmpty) {
      return tests;
    }

    final lowerTags = tags.map((t) => t.toLowerCase()).toSet();

    return tests.where((t) {
      final testTags = t.tags.map((tag) => tag.toLowerCase()).toSet();
      return testTags.containsAll(lowerTags);
    }).toList();
  }

  /// Sorts a list of tests according to the given [sortOption].
  List<TestModel> _sortTests(List<TestModel> tests, TestSortOption sortOption) {
    switch (sortOption) {
      case TestSortOption.mostAttempts:
        tests.sort((a, b) => b.attemptCount.compareTo(a.attemptCount));
      case TestSortOption.fewestAttempts:
        tests.sort((a, b) => a.attemptCount.compareTo(b.attemptCount));
      case TestSortOption.mostQuestions:
        tests.sort((a, b) => b.questionCount.compareTo(a.questionCount));
      case TestSortOption.fewestQuestions:
        tests.sort((a, b) => a.questionCount.compareTo(b.questionCount));
      case TestSortOption.newest:
        tests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TestSortOption.oldest:
        tests.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case TestSortOption.alphabetical:
        tests.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return tests;
  }

  /// --------------------------------------------------------------------------
  /// ATTEMPT MANAGEMENT
  /// --------------------------------------------------------------------------

  /// Records a new attempt for the test.
  Future<void> addAttempt(String testId, TestAttempt attempt) async {
    await _testCollection.doc(testId).update({
      TestModelFieldConstants.attempts: FieldValue.arrayUnion([
        attempt.toJson(),
      ]),
    });
  }
}
