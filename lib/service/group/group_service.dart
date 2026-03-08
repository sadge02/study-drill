import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/connect/connect_model.dart';
import '../../models/flashcard/flashcard_model.dart';
import '../../models/group/group_model.dart';
import '../../models/test/test_model.dart';
import '../../utils/constants/collections/database_constants.dart';
import '../../utils/constants/error/messages/firebase_exception_constants.dart';
import '../../utils/constants/models/connect/connect_model_field_constants.dart';
import '../../utils/constants/models/flashcard/flashcard_model_field_constants.dart';
import '../../utils/constants/models/group/group_model_field_constants.dart';
import '../../utils/constants/models/test/test_model_field_constants.dart';
import '../../utils/constants/models/user/user_model_field_constants.dart';
import '../../utils/enums/group/group_role_enum.dart';
import '../../utils/enums/group/group_sort_option_enum.dart';

class GroupService {
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _groupCollection =>
      _database.collection(DatabaseConstants.groupsCollection);

  CollectionReference<Map<String, dynamic>> get _userCollection =>
      _database.collection(DatabaseConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _testCollection =>
      _database.collection(DatabaseConstants.testsCollection);

  CollectionReference<Map<String, dynamic>> get _flashcardCollection =>
      _database.collection(DatabaseConstants.flashcardsCollection);

  CollectionReference<Map<String, dynamic>> get _connectCollection =>
      _database.collection(DatabaseConstants.connectsCollection);

  /// --------------------------------------------------------------------------
  /// CREATE
  /// --------------------------------------------------------------------------

  /// Creates a new group document in Firestore and adds the group ID to the
  /// author's [groupIds] list atomically.
  Future<String?> createGroup(GroupModel group) async {
    try {
      final batch = _database.batch();

      batch.set(_groupCollection.doc(group.id), group.toJson());

      batch.update(_userCollection.doc(group.authorId), {
        UserModelFieldConstants.groupIds: FieldValue.arrayUnion([group.id]),
      });

      await batch.commit();
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupCreateFailedMessage;
    }
  }

  /// --------------------------------------------------------------------------
  /// READ
  /// --------------------------------------------------------------------------

  /// Fetches a single group by its [groupId].
  Future<GroupModel?> getGroupById(String groupId) async {
    final document = await _groupCollection.doc(groupId).get();
    if (!document.exists || document.data() == null) {
      return null;
    }
    return GroupModel.fromJson(document.data()!);
  }

  /// Returns a real-time stream of a single group.
  Stream<GroupModel?> streamGroupById(String groupId) {
    return _groupCollection.doc(groupId).snapshots().map((document) {
      if (!document.exists || document.data() == null) {
        return null;
      }
      return GroupModel.fromJson(document.data()!);
    });
  }

  /// Fetches every group document in the collection.
  Future<List<GroupModel>> getAllGroups() async {
    final snapshot = await _groupCollection.get();
    return snapshot.docs
        .map((document) => GroupModel.fromJson(document.data()))
        .toList();
  }

  /// Returns a real-time stream of every group document.
  Stream<List<GroupModel>> streamAllGroups() {
    return _groupCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((document) => GroupModel.fromJson(document.data()))
          .toList(),
    );
  }

  /// Fetches all groups where the given user is the author.
  Future<List<GroupModel>> getGroupsByAuthorId(String authorId) async {
    final snapshot = await _groupCollection
        .where(GroupModelFieldConstants.authorId, isEqualTo: authorId)
        .get();
    return snapshot.docs
        .map((document) => GroupModel.fromJson(document.data()))
        .toList();
  }

  /// Returns a real-time stream of all groups authored by a user.
  Stream<List<GroupModel>> streamGroupsByAuthorId(String authorId) {
    return _groupCollection
        .where(GroupModelFieldConstants.authorId, isEqualTo: authorId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => GroupModel.fromJson(document.data()))
              .toList(),
        );
  }

  /// Fetches all groups where the user holds the given [role].
  Future<List<GroupModel>> getGroupsByUserRole(
    String userId,
    GroupRole role,
  ) async {
    final snapshot = await _buildRoleQuery(userId, role).get();
    return snapshot.docs
        .map((document) => GroupModel.fromJson(document.data()))
        .toList();
  }

  /// Returns a real-time stream of all groups where the user holds [role].
  Stream<List<GroupModel>> streamGroupsByUserRole(
    String userId,
    GroupRole role,
  ) {
    return _buildRoleQuery(userId, role).snapshots().map(
      (snapshot) => snapshot.docs
          .map((document) => GroupModel.fromJson(document.data()))
          .toList(),
    );
  }

  /// Builds the correct Firestore query for the given [role].
  Query<Map<String, dynamic>> _buildRoleQuery(String userId, GroupRole role) {
    switch (role) {
      case GroupRole.author:
        return _groupCollection.where(
          GroupModelFieldConstants.authorId,
          isEqualTo: userId,
        );
      case GroupRole.admin:
        return _groupCollection.where(
          GroupModelFieldConstants.adminIds,
          arrayContains: userId,
        );
      case GroupRole.creator:
        return _groupCollection.where(
          GroupModelFieldConstants.creatorIds,
          arrayContains: userId,
        );
      case GroupRole.member:
        return _groupCollection.where(
          GroupModelFieldConstants.userIds,
          arrayContains: userId,
        );
    }
  }

  /// --------------------------------------------------------------------------
  /// FILTERING & SORTING
  /// --------------------------------------------------------------------------

  /// Fetches all groups and applies optional client-side filters and sorting.
  ///
  /// - [titleStartsWith]: keeps only groups whose title starts with this
  ///   string (case-insensitive).
  /// - [tags]: keeps only groups that contain **all** of the provided tags.
  /// - [visibility]: keeps only groups matching this visibility.
  /// - [sortOption]: determines the sort order of the returned list.
  Future<List<GroupModel>> getFilteredGroups({
    String? titleStartsWith,
    List<String>? tags,
    GroupVisibility? visibility,
    GroupSortOption sortOption = GroupSortOption.newest,
  }) async {
    List<GroupModel> groups = await getAllGroups();

    groups = _filterByTitle(groups, titleStartsWith);
    groups = _filterByTags(groups, tags);
    groups = _filterByVisibility(groups, visibility);
    groups = _sortGroups(groups, sortOption);

    return groups;
  }

  /// Returns a real-time stream of all groups with filters and sorting.
  Stream<List<GroupModel>> streamFilteredGroups({
    String? titleStartsWith,
    List<String>? tags,
    GroupVisibility? visibility,
    GroupSortOption sortOption = GroupSortOption.newest,
  }) {
    return streamAllGroups().map((groups) {
      List<GroupModel> result = groups;

      result = _filterByTitle(result, titleStartsWith);
      result = _filterByTags(result, tags);
      result = _filterByVisibility(result, visibility);
      result = _sortGroups(result, sortOption);

      return result;
    });
  }

  /// Fetches all groups for a user [role] and applies filter and sorting.
  Future<List<GroupModel>> getFilteredGroupsByUserRole(
    String userId,
    GroupRole role, {
    String? titleStartsWith,
    List<String>? tags,
    GroupVisibility? visibility,
    GroupSortOption sortOption = GroupSortOption.newest,
  }) async {
    List<GroupModel> groups = await getGroupsByUserRole(userId, role);

    groups = _filterByTitle(groups, titleStartsWith);
    groups = _filterByTags(groups, tags);
    groups = _filterByVisibility(groups, visibility);
    groups = _sortGroups(groups, sortOption);

    return groups;
  }

  /// Returns a real-time stream of groups for a specific user [role] with filters and sorting.
  Stream<List<GroupModel>> streamFilteredGroupsByUserRole(
    String userId,
    GroupRole role, {
    String? titleStartsWith,
    List<String>? tags,
    GroupVisibility? visibility,
    GroupSortOption sortOption = GroupSortOption.newest,
  }) {
    return streamGroupsByUserRole(userId, role).map((groups) {
      List<GroupModel> result = groups;

      result = _filterByTitle(result, titleStartsWith);
      result = _filterByTags(result, tags);
      result = _filterByVisibility(result, visibility);
      result = _sortGroups(result, sortOption);

      return result;
    });
  }

  /// Filters groups whose title starts with [prefix].
  List<GroupModel> _filterByTitle(List<GroupModel> groups, String? prefix) {
    if (prefix == null || prefix.isEmpty) return groups;
    final lowerPrefix = prefix.toLowerCase();
    return groups
        .where((group) => group.title.toLowerCase().startsWith(lowerPrefix))
        .toList();
  }

  /// Filters groups that contain **all** of the provided [tags].
  List<GroupModel> _filterByTags(List<GroupModel> groups, List<String>? tags) {
    if (tags == null || tags.isEmpty) return groups;
    final lowerTags = tags.map((t) => t.toLowerCase()).toSet();
    return groups.where((group) {
      final groupTags = group.tags.map((t) => t.toLowerCase()).toSet();
      return groupTags.containsAll(lowerTags);
    }).toList();
  }

  /// Filters groups by [visibility].
  List<GroupModel> _filterByVisibility(
    List<GroupModel> groups,
    GroupVisibility? visibility,
  ) {
    if (visibility == null) {
      return groups;
    }
    return groups.where((group) => group.visibility == visibility).toList();
  }

  /// Sorts a list of groups according to the given [sortOption].
  List<GroupModel> _sortGroups(
    List<GroupModel> groups,
    GroupSortOption sortOption,
  ) {
    switch (sortOption) {
      case GroupSortOption.newest:
        groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case GroupSortOption.oldest:
        groups.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case GroupSortOption.recentlyUpdated:
        groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case GroupSortOption.leastRecentlyUpdated:
        groups.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case GroupSortOption.memberCount:
        groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
      case GroupSortOption.mostContent:
        groups.sort(
          (a, b) => b.totalContentCount.compareTo(a.totalContentCount),
        );
      case GroupSortOption.alphabetical:
        groups.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return groups;
  }

  /// Fetches all tests that belong to the given group.
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

  /// Fetches all flashcard sets that belong to the given group.
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

  /// Fetches all connect games that belong to the given group.
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

  /// --------------------------------------------------------------------------
  /// UPDATE
  /// --------------------------------------------------------------------------

  /// Updates a group document with the provided [group].
  Future<String?> updateGroup(
    GroupModel group, {
    required String updatedBy,
  }) async {
    try {
      final existing = await getGroupById(group.id);
      if (existing == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (existing.authorId != updatedBy && !existing.isAdmin(updatedBy)) {
        return FirebaseExceptionConstants.groupUpdateNotAuthorMessage;
      }

      await _groupCollection.doc(group.id).set(group.toJson());
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupUpdateFailedMessage;
    }
  }

  /// Adds a single content ID to the appropriate array on the group document.
  Future<void> addContentId(
    String groupId, {
    String? testId,
    String? flashcardId,
    String? connectId,
  }) async {
    final Map<String, dynamic> updates = {
      GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
    };

    if (testId != null) {
      updates[GroupModelFieldConstants.testIds] = FieldValue.arrayUnion([
        testId,
      ]);
    }
    if (flashcardId != null) {
      updates[GroupModelFieldConstants.flashcardIds] = FieldValue.arrayUnion([
        flashcardId,
      ]);
    }
    if (connectId != null) {
      updates[GroupModelFieldConstants.connectIds] = FieldValue.arrayUnion([
        connectId,
      ]);
    }

    await _groupCollection.doc(groupId).update(updates);
  }

  /// Removes a content ID from the appropriate array on the group document.
  Future<void> removeContentId(
    String groupId, {
    String? testId,
    String? flashcardId,
    String? connectId,
  }) async {
    final Map<String, dynamic> updates = {
      GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
    };

    if (testId != null) {
      updates[GroupModelFieldConstants.testIds] = FieldValue.arrayRemove([
        testId,
      ]);
    }
    if (flashcardId != null) {
      updates[GroupModelFieldConstants.flashcardIds] = FieldValue.arrayRemove([
        flashcardId,
      ]);
    }
    if (connectId != null) {
      updates[GroupModelFieldConstants.connectIds] = FieldValue.arrayRemove([
        connectId,
      ]);
    }

    await _groupCollection.doc(groupId).update(updates);
  }

  /// --------------------------------------------------------------------------
  /// MEMBER MANAGEMENT
  /// --------------------------------------------------------------------------

  /// Adds a user to the group as a member. If the group's settings have
  /// [autoAddAsEditor] enabled, the user is also added as a creator.
  ///
  /// Also adds the group ID to the user's [groupIds] list atomically.
  Future<String?> addMember(String groupId, String userId) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.isMember(userId)) {
        return FirebaseExceptionConstants.userAlreadyAMemberMessage;
      }

      final batch = _database.batch();

      final Map<String, dynamic> groupUpdates = {
        GroupModelFieldConstants.userIds: FieldValue.arrayUnion([userId]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      };

      if (group.autoAddAsEditor) {
        groupUpdates[GroupModelFieldConstants.creatorIds] =
            FieldValue.arrayUnion([userId]);
      }

      batch.update(_groupCollection.doc(groupId), groupUpdates);

      batch.update(_userCollection.doc(userId), {
        UserModelFieldConstants.groupIds: FieldValue.arrayUnion([groupId]),
      });

      await batch.commit();
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.userUnsuccessfullyJoinedMessage;
    }
  }

  /// Allows a user to leave the group voluntarily.
  ///
  /// The **author** cannot leave — they must transfer ownership or delete the
  /// group first. Removes the user from member, admin, and creator lists,
  /// removes the group ID from their [groupIds], and cleans up their
  /// statistics for this group.
  Future<String?> leaveGroup(String groupId, String userId) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.authorId == userId) {
        return FirebaseExceptionConstants.groupOwnerLeaveMessage;
      }

      final batch = _database.batch();

      batch.update(_groupCollection.doc(groupId), {
        GroupModelFieldConstants.userIds: FieldValue.arrayRemove([userId]),
        GroupModelFieldConstants.adminIds: FieldValue.arrayRemove([userId]),
        GroupModelFieldConstants.creatorIds: FieldValue.arrayRemove([userId]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });

      batch.update(_userCollection.doc(userId), {
        UserModelFieldConstants.groupIds: FieldValue.arrayRemove([groupId]),
        '${UserModelFieldConstants.statistics}.$groupId': FieldValue.delete(),
      });

      await batch.commit();
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupLeaveFailedMessage;
    }
  }

  /// Kicks a member from the group.
  Future<String?> kickMember(
    String groupId,
    String userId, {
    required String kickedBy,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) return FirebaseExceptionConstants.groupDoesNotExist;

      if (group.authorId != kickedBy && !group.isAdmin(kickedBy)) {
        return FirebaseExceptionConstants.groupUpdateNotAuthorMessage;
      }

      if (group.authorId == userId) {
        return FirebaseExceptionConstants.groupCannotKickOwnerMessage;
      }

      if (!group.isMember(userId)) {
        return FirebaseExceptionConstants.groupUserNotAMemberMessage;
      }

      final batch = _database.batch();

      batch.update(_groupCollection.doc(groupId), {
        GroupModelFieldConstants.userIds: FieldValue.arrayRemove([userId]),
        GroupModelFieldConstants.adminIds: FieldValue.arrayRemove([userId]),
        GroupModelFieldConstants.creatorIds: FieldValue.arrayRemove([userId]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });

      batch.update(_userCollection.doc(userId), {
        UserModelFieldConstants.groupIds: FieldValue.arrayRemove([groupId]),
        '${UserModelFieldConstants.statistics}.$groupId': FieldValue.delete(),
      });

      await batch.commit();
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupKickMemberFailedMessage;
    }
  }

  /// Promotes a member to admin.
  Future<String?> promoteToAdmin(
    String groupId,
    String userId, {
    required String promotedBy,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.authorId != promotedBy) {
        return FirebaseExceptionConstants.groupOnlyAuthorCanManageAdminsMessage;
      }

      if (!group.isMember(userId)) {
        return FirebaseExceptionConstants.groupUserNotAMemberMessage;
      }

      await _groupCollection.doc(groupId).update({
        GroupModelFieldConstants.adminIds: FieldValue.arrayUnion([userId]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupRoleChangeFailedMessage;
    }
  }

  /// Demotes an admin back to a regular member.
  Future<String?> demoteFromAdmin(
    String groupId,
    String userId, {
    required String demotedBy,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.authorId != demotedBy) {
        return FirebaseExceptionConstants.groupOnlyAuthorCanManageAdminsMessage;
      }

      await _groupCollection.doc(groupId).update({
        GroupModelFieldConstants.adminIds: FieldValue.arrayRemove([userId]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupRoleChangeFailedMessage;
    }
  }

  /// Promotes a member to creator (editor).
  Future<String?> promoteToCreator(
    String groupId,
    String userId, {
    required String promotedBy,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.authorId != promotedBy && !group.isAdmin(promotedBy)) {
        return FirebaseExceptionConstants.groupUpdateNotAuthorMessage;
      }

      if (!group.isMember(userId)) {
        return FirebaseExceptionConstants.groupUserNotAMemberMessage;
      }

      await _groupCollection.doc(groupId).update({
        GroupModelFieldConstants.creatorIds: FieldValue.arrayUnion([userId]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupRoleChangeFailedMessage;
    }
  }

  /// Demotes a creator back to a regular member.
  Future<String?> demoteFromCreator(
    String groupId,
    String userId, {
    required String demotedBy,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.authorId != demotedBy && !group.isAdmin(demotedBy)) {
        return FirebaseExceptionConstants.groupUpdateNotAuthorMessage;
      }

      await _groupCollection.doc(groupId).update({
        GroupModelFieldConstants.creatorIds: FieldValue.arrayRemove([userId]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupRoleChangeFailedMessage;
    }
  }

  /// Transfers group ownership to another member.
  ///
  /// The new owner must already be a member of the group. The old author is
  /// kept as an admin after the transfer.
  Future<String?> transferOwnership(
    String groupId,
    String newOwnerId, {
    required String transferredBy,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.authorId != transferredBy) {
        return FirebaseExceptionConstants
            .groupNonAuthorTransferOwnershipMessage;
      }

      if (!group.isMember(newOwnerId)) {
        return FirebaseExceptionConstants.groupNewOwnerMustBeMemberMessage;
      }

      await _groupCollection.doc(groupId).update({
        GroupModelFieldConstants.authorId: newOwnerId,
        GroupModelFieldConstants.adminIds: FieldValue.arrayUnion([
          transferredBy,
          newOwnerId,
        ]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });

      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupTransferOwnershipFailedMessage;
    }
  }

  /// --------------------------------------------------------------------------
  /// JOIN REQUESTS
  /// --------------------------------------------------------------------------

  /// Submits a join request for the group. If the group does not require
  /// approval the user is added immediately.
  Future<String?> requestToJoin(String groupId, String userId) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.isMember(userId)) {
        return FirebaseExceptionConstants.userAlreadyAMemberMessage;
      }

      final alreadyRequested = group.joinRequests.any(
        (request) => request.userId == userId,
      );
      if (alreadyRequested) {
        return FirebaseExceptionConstants.userAlreadyRequestedMessage;
      }

      if (!group.settings.requiresJoinApproval) {
        return await addMember(groupId, userId);
      }

      final request = GroupJoinRequest(
        id: _database.collection('_').doc().id,
        userId: userId,
        createdAt: DateTime.now(),
      );

      await _groupCollection.doc(groupId).update({
        GroupModelFieldConstants.joinRequests: FieldValue.arrayUnion([
          request.toJson(),
        ]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });

      return null;
    } catch (_) {
      return FirebaseExceptionConstants.userUnsuccessfullyJoinedMessage;
    }
  }

  /// Approves a pending join request and adds the user to the group.
  Future<String?> approveJoinRequest(
    String groupId,
    String userId, {
    required String approvedBy,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.authorId != approvedBy && !group.isAdmin(approvedBy)) {
        return FirebaseExceptionConstants.groupUpdateNotAuthorMessage;
      }

      final request = group.joinRequests.where(
        (request) => request.userId == userId,
      );
      if (request.isEmpty) {
        return FirebaseExceptionConstants.userNotInPendingListMessage;
      }

      // Remove the join request from the list.
      await _groupCollection.doc(groupId).update({
        GroupModelFieldConstants.joinRequests: FieldValue.arrayRemove([
          request.first.toJson(),
        ]),
      });

      // Add the user as a member.
      final addResult = await addMember(groupId, userId);
      if (addResult != null) {
        return addResult;
      }

      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupJoinRequestApprovalFailedMessage;
    }
  }

  /// Rejects a pending join request.
  Future<String?> rejectJoinRequest(
    String groupId,
    String userId, {
    required String rejectedBy,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.authorId != rejectedBy && !group.isAdmin(rejectedBy)) {
        return FirebaseExceptionConstants.groupUpdateNotAuthorMessage;
      }

      final request = group.joinRequests.where(
        (request) => request.userId == userId,
      );
      if (request.isEmpty) {
        return FirebaseExceptionConstants.userNotInPendingListMessage;
      }

      await _groupCollection.doc(groupId).update({
        GroupModelFieldConstants.joinRequests: FieldValue.arrayRemove([
          request.first.toJson(),
        ]),
        GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });

      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupJoinRequestRejectionFailedMessage;
    }
  }

  /// --------------------------------------------------------------------------
  /// DELETE
  /// --------------------------------------------------------------------------

  /// Deletes a group and all of its transitive data.
  Future<String?> deleteGroup(
    String groupId, {
    required String deletedBy,
  }) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) {
        return FirebaseExceptionConstants.groupDoesNotExist;
      }

      if (group.authorId != deletedBy) {
        return FirebaseExceptionConstants.groupNonOwnerDeleteMessage;
      }

      final List<DocumentReference> contentToDelete = [];

      final testSnapshot = await _testCollection
          .where(TestModelFieldConstants.groupId, isEqualTo: groupId)
          .get();
      for (final document in testSnapshot.docs) {
        contentToDelete.add(document.reference);
      }

      final flashcardSnapshot = await _flashcardCollection
          .where(FlashcardModelFieldConstants.groupId, isEqualTo: groupId)
          .get();
      for (final document in flashcardSnapshot.docs) {
        contentToDelete.add(document.reference);
      }

      final connectSnapshot = await _connectCollection
          .where(ConnectModelFieldConstants.groupId, isEqualTo: groupId)
          .get();
      for (final document in connectSnapshot.docs) {
        contentToDelete.add(document.reference);
      }

      final Set<String> affectedUserIds = {
        ...group.userIds,
        ...group.adminIds,
        ...group.creatorIds,
        ...group.joinRequests.map((request) => request.userId),
        group.authorId,
      };

      final Map<String, List<Map<String, dynamic>>> cleanedRequests = {};

      for (final userId in affectedUserIds) {
        final userDoc = await _userCollection.doc(userId).get();
        if (userDoc.exists && userDoc.data() != null) {
          final rawRequests =
              userDoc.data()![UserModelFieldConstants.requests]
                  as List<dynamic>? ??
              [];

          final filtered = rawRequests
              .cast<Map<String, dynamic>>()
              .where(
                (request) =>
                    request[UserModelFieldConstants.requestGroupId] != groupId,
              )
              .toList();

          if (filtered.length != rawRequests.length) {
            cleanedRequests[userId] = filtered;
          }
        }
      }

      WriteBatch batch = _database.batch();
      int operationCount = 0;

      Future<void> commitIfNeeded() async {
        if (operationCount >= DatabaseConstants.batchLimit) {
          await batch.commit();
          batch = _database.batch();
          operationCount = 0;
        }
      }

      for (final ref in contentToDelete) {
        batch.delete(ref);
        operationCount++;
        await commitIfNeeded();
      }

      for (final userId in affectedUserIds) {
        batch.update(_userCollection.doc(userId), {
          UserModelFieldConstants.groupIds: FieldValue.arrayRemove([groupId]),
          '${UserModelFieldConstants.statistics}.$groupId': FieldValue.delete(),
        });
        operationCount++;
        await commitIfNeeded();
      }

      for (final entry in cleanedRequests.entries) {
        batch.update(_userCollection.doc(entry.key), {
          UserModelFieldConstants.requests: entry.value,
        });
        operationCount++;
        await commitIfNeeded();
      }

      batch.delete(_groupCollection.doc(groupId));
      operationCount++;

      await batch.commit();

      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupDeleteFailedMessage;
    }
  }
}
