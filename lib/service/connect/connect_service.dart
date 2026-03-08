import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/connect/connect_model.dart';
import '../../utils/constants/collections/database_constants.dart';
import '../../utils/constants/models/connect/connect_model_field_constants.dart';
import '../../utils/enums/connect/connect_sort_option_enum.dart';
import '../group/group_service.dart';

class ConnectService {
  final GroupService _groupService = GroupService();

  final CollectionReference<Map<String, dynamic>> _connectCollection =
      FirebaseFirestore.instance.collection(
        DatabaseConstants.connectsCollection,
      );

  /// --------------------------------------------------------------------------
  /// CREATE
  /// --------------------------------------------------------------------------

  /// Creates a new connect game document in Firestore and registers it on the
  /// group.
  Future<void> createConnect(ConnectModel connect) async {
    await _connectCollection.doc(connect.id).set(connect.toJson());
    await _groupService.addContentId(connect.groupId, connectId: connect.id);
  }

  /// --------------------------------------------------------------------------
  /// READ
  /// --------------------------------------------------------------------------

  /// Fetches a single connect game by its [connectId].
  Future<ConnectModel?> getConnectById(String connectId) async {
    final document = await _connectCollection.doc(connectId).get();
    if (!document.exists || document.data() == null) {
      return null;
    }
    return ConnectModel.fromJson(document.data()!);
  }

  /// Returns a real-time stream of a single connect game.
  Stream<ConnectModel?> streamConnectById(String connectId) {
    return _connectCollection.doc(connectId).snapshots().map((document) {
      if (!document.exists || document.data() == null) {
        return null;
      }
      return ConnectModel.fromJson(document.data()!);
    });
  }

  /// Fetches all connect games belonging to a specific group.
  Future<List<ConnectModel>> getConnectsByGroupId(String groupId) async {
    final snapshot = await _connectCollection
        .where(ConnectModelFieldConstants.groupId, isEqualTo: groupId)
        .get();
    return snapshot.docs
        .map((document) => ConnectModel.fromJson(document.data()))
        .toList();
  }

  /// Returns a real-time stream of all connect games in a group.
  Stream<List<ConnectModel>> streamConnectsByGroupId(String groupId) {
    return _connectCollection
        .where(ConnectModelFieldConstants.groupId, isEqualTo: groupId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => ConnectModel.fromJson(document.data()))
              .toList(),
        );
  }

  /// Fetches all connect games created by a specific user.
  Future<List<ConnectModel>> getConnectsByAuthorId(String authorId) async {
    final snapshot = await _connectCollection
        .where(ConnectModelFieldConstants.authorId, isEqualTo: authorId)
        .get();
    return snapshot.docs
        .map((document) => ConnectModel.fromJson(document.data()))
        .toList();
  }

  /// --------------------------------------------------------------------------
  /// UPDATE
  /// --------------------------------------------------------------------------

  /// Updates a connect game document with the provided [ConnectModel].
  Future<void> updateConnect(ConnectModel connect) async {
    await _connectCollection.doc(connect.id).set(connect.toJson());
  }

  /// --------------------------------------------------------------------------
  /// DELETE
  /// --------------------------------------------------------------------------

  /// Deletes a connect game document from Firestore and removes its ID from
  /// the group.
  Future<void> deleteConnect(String connectId) async {
    final connect = await getConnectById(connectId);
    await _connectCollection.doc(connectId).delete();

    if (connect != null) {
      await _groupService.removeContentId(
        connect.groupId,
        connectId: connect.id,
      );
    }
  }

  /// --------------------------------------------------------------------------
  /// FILTERING & SORTING
  /// --------------------------------------------------------------------------

  /// Fetches all connect games for a group and applies optional filters and
  /// sorting.
  ///
  /// - [titleStartsWith]: keeps only games whose title starts with this
  ///   string (case-insensitive).
  /// - [tags]: keeps only games that contain **all** of the provided tags.
  /// - [sortOption]: determines the sort order of the returned list.
  Future<List<ConnectModel>> getFilteredConnectsByGroupId(
    String groupId, {
    String? titleStartsWith,
    List<String>? tags,
    ConnectSortOption sortOption = ConnectSortOption.newest,
  }) async {
    List<ConnectModel> connects = await getConnectsByGroupId(groupId);

    connects = _filterByTitle(connects, titleStartsWith);
    connects = _filterByTags(connects, tags);
    connects = _sortConnects(connects, sortOption);

    return connects;
  }

  /// Returns a real-time stream of connect games for a group with optional
  /// filters and sorting applied.
  Stream<List<ConnectModel>> streamFilteredConnectsByGroupId(
    String groupId, {
    String? titleStartsWith,
    List<String>? tags,
    ConnectSortOption sortOption = ConnectSortOption.newest,
  }) {
    return streamConnectsByGroupId(groupId).map((connects) {
      List<ConnectModel> result = connects;

      result = _filterByTitle(result, titleStartsWith);
      result = _filterByTags(result, tags);
      result = _sortConnects(result, sortOption);

      return result;
    });
  }

  /// Filters connects whose title starts with [prefix] (case-insensitive).
  List<ConnectModel> _filterByTitle(
    List<ConnectModel> connects,
    String? prefix,
  ) {
    if (prefix == null || prefix.isEmpty) {
      return connects;
    }

    final lowerPrefix = prefix.toLowerCase();

    return connects
        .where((c) => c.title.toLowerCase().startsWith(lowerPrefix))
        .toList();
  }

  /// Filters connects that contain **all** of the provided [tags].
  List<ConnectModel> _filterByTags(
    List<ConnectModel> connects,
    List<String>? tags,
  ) {
    if (tags == null || tags.isEmpty) {
      return connects;
    }

    final lowerTags = tags.map((t) => t.toLowerCase()).toSet();

    return connects.where((c) {
      final connectTags = c.tags.map((t) => t.toLowerCase()).toSet();
      return connectTags.containsAll(lowerTags);
    }).toList();
  }

  /// Sorts a list of connects according to the given [sortOption].
  List<ConnectModel> _sortConnects(
    List<ConnectModel> connects,
    ConnectSortOption sortOption,
  ) {
    switch (sortOption) {
      case ConnectSortOption.mostAttempts:
        connects.sort((a, b) => b.attemptCount.compareTo(a.attemptCount));
      case ConnectSortOption.fewestAttempts:
        connects.sort((a, b) => a.attemptCount.compareTo(b.attemptCount));
      case ConnectSortOption.mostPairs:
        connects.sort((a, b) => b.pairCount.compareTo(a.pairCount));
      case ConnectSortOption.fewestPairs:
        connects.sort((a, b) => a.pairCount.compareTo(b.pairCount));
      case ConnectSortOption.newest:
        connects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ConnectSortOption.oldest:
        connects.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ConnectSortOption.alphabetical:
        connects.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return connects;
  }

  /// --------------------------------------------------------------------------
  /// ATTEMPT MANAGEMENT
  /// --------------------------------------------------------------------------

  /// Records a new attempt for the connect game.
  Future<void> addAttempt(String connectId, ConnectAttempt attempt) async {
    await _connectCollection.doc(connectId).update({
      ConnectModelFieldConstants.attempts: FieldValue.arrayUnion([
        attempt.toJson(),
      ]),
    });
  }
}
