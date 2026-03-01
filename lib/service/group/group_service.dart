import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_drill/models/group/group_model.dart';
import 'package:study_drill/utils/constants/collections/database_constants.dart';

import '../../utils/constants/error/messages/firebase_exception_constants.dart';
import '../../utils/constants/models/group_model_field_constants.dart';
import '../../utils/constants/models/user_model_field_constants.dart';
import '../../utils/enums/group/group_sort_option_enum.dart';

class GroupService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  static const String _groupsCollection = DatabaseConstants.groupsCollection;
  static const String _usersCollection = DatabaseConstants.usersCollection;

  String? get currentUid => _authentication.currentUser?.uid;

  Future<String?> createGroup({
    required String name,
    required String summary,
    required String profilePic,
    required GroupVisibility visibility,
    required GroupSettings settings,
    List<String> tags = const [],
  }) async {
    try {
      final uid = currentUid;
      if (uid == null) {
        return FirebaseExceptionConstants.userNotLoggedInMessage;
      }

      final groupDocument = _database.collection(_groupsCollection).doc();

      final groupId = groupDocument.id;

      final group = GroupModel(
        id: groupId,
        name: name.trim(),
        nameLowercase: name.trim().toLowerCase(),
        summary: summary,
        profilePic: profilePic,
        authorId: uid,
        visibility: visibility,
        settings: settings,
        tags: tags,
        userIds: [uid],
        adminIds: [uid],
        editorUserIds: [uid],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final WriteBatch batch = _database.batch();

      batch.set(groupDocument, group.toJson());

      batch.update(_database.collection(_usersCollection).doc(uid), {
        UserModelFieldConstants.groupIds: FieldValue.arrayUnion([groupId]),
      });

      await batch.commit();

      return null;
    } catch (_) {
      return FirebaseExceptionConstants.groupCreateFailedMessage;
    }
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final document = await _database
          .collection(_groupsCollection)
          .doc(groupId)
          .get();

      if (!document.exists || document.data() == null) {
        return null;
      }

      return GroupModel.fromJson(document.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<String?> joinGroup(GroupModel group) async {
    try {
      final uid = currentUid;

      if (uid == null) {
        return FirebaseExceptionConstants.userNotLoggedInMessage;
      }

      if (group.userIds.contains(uid)) {
        return FirebaseExceptionConstants.userAlreadyAMemberMessage;
      }
      if (group.pendingUserRequestIds.contains(uid)) {
        return FirebaseExceptionConstants.userAlreadyRequestedMessage;
      }

      final groupReference = _database
          .collection(_groupsCollection)
          .doc(group.id);
      final userReference = _database.collection(_usersCollection).doc(uid);

      final batch = _database.batch();

      if (group.visibility == GroupVisibility.public) {
        batch.update(groupReference, {
          GroupModelFieldConstants.userIds: FieldValue.arrayUnion([uid]),
          if (group.settings.autoAddAsEditor)
            GroupModelFieldConstants.editorUserIds: FieldValue.arrayUnion([
              uid,
            ]),
          GroupModelFieldConstants.updatedAt: FieldValue.serverTimestamp(),
        });

        batch.update(userReference, {
          UserModelFieldConstants.groupIds: FieldValue.arrayUnion([group.id]),
        });

        await batch.commit();

        return '${FirebaseExceptionConstants.userSuccessfullyJoinedMessage} ${group.name}!';
      } else {
        batch.update(groupReference, {
          GroupModelFieldConstants.pendingUserRequestIds: FieldValue.arrayUnion(
            [uid],
          ),
        });

        await batch.commit();

        return FirebaseExceptionConstants.userJoinRequestMessage;
      }
    } catch (exception) {
      return '${FirebaseExceptionConstants.userUnsuccessfullyJoinedMessage}: $exception';
    }
  }

  Future<String?> leaveGroup(String groupId) async {
    try {
      final uid = currentUid;

      if (uid == null) {
        return FirebaseExceptionConstants.userNotLoggedInMessage;
      }

      return await _database.runTransaction((transaction) async {
        final groupReference = _database
            .collection(_groupsCollection)
            .doc(groupId);
        final userReference = _database.collection(_usersCollection).doc(uid);

        final groupSnapshot = await transaction.get(groupReference);

        if (!groupSnapshot.exists) {
          return FirebaseExceptionConstants.groupDoesNotExist;
        }

        final data = groupSnapshot.data();

        final authorId = data?[GroupModelFieldConstants.authorId];

        final userIds = List<String>.from(
          (data?[GroupModelFieldConstants.userIds] as List?) ?? [],
        );

        if (uid == authorId) {
          if (userIds.length > 1) {
            return FirebaseExceptionConstants.groupOwnerLeaveMessage;
          } else {
            transaction.delete(groupReference);
          }
        } else {
          transaction.update(groupReference, {
            GroupModelFieldConstants.userIds: FieldValue.arrayRemove([uid]),
            GroupModelFieldConstants.adminIds: FieldValue.arrayRemove([uid]),
            GroupModelFieldConstants.editorUserIds: FieldValue.arrayRemove([
              uid,
            ]), //
            GroupModelFieldConstants.updatedAt: FieldValue.serverTimestamp(),
          });
        }

        transaction.update(userReference, {
          UserModelFieldConstants.groupIds: FieldValue.arrayRemove([groupId]),
        });

        return FirebaseExceptionConstants.groupLeaveSuccessMessage;
      });
    } catch (_) {
      return FirebaseExceptionConstants.groupLeaveFailedMessage;
    }
  }

  Future<String?> transferOwnership(String groupId, String newAuthorId) async {
    try {
      final uid = currentUid;

      if (uid == null) {
        return FirebaseExceptionConstants.userNotLoggedInMessage;
      }

      return await _database.runTransaction((transaction) async {
        final groupReference = _database
            .collection(_groupsCollection)
            .doc(groupId);

        final groupSnapshot = await transaction.get(groupReference);

        if (!groupSnapshot.exists) {
          return FirebaseExceptionConstants.groupDoesNotExist;
        }

        final data = groupSnapshot.data();

        final currentAuthorId = data?[GroupModelFieldConstants.authorId];

        final userIds = List<String>.from(
          (data?[GroupModelFieldConstants.userIds] as List?) ?? [],
        );

        if (uid != currentAuthorId) {
          return FirebaseExceptionConstants
              .groupNonAuthorTransferOwnershipMessage;
        }

        if (!userIds.contains(newAuthorId)) {
          return FirebaseExceptionConstants.groupNewOwnerMustBeMemberMessage;
        }

        transaction.update(groupReference, {
          GroupModelFieldConstants.authorId: newAuthorId,
          GroupModelFieldConstants.adminIds: FieldValue.arrayUnion([
            newAuthorId,
          ]),
          GroupModelFieldConstants.updatedAt: FieldValue.serverTimestamp(),
        });

        return FirebaseExceptionConstants.groupTransferOwnershipSuccessMessage;
      });
    } catch (_) {
      return FirebaseExceptionConstants.groupTransferOwnershipFailedMessage;
    }
  }

  Future<String?> deleteGroup(String groupId) async {
    try {
      final uid = currentUid;
      if (uid == null) {
        return FirebaseExceptionConstants.userNotLoggedInMessage;
      }

      return await _database.runTransaction((transaction) async {
        final groupReference = _database
            .collection(_groupsCollection)
            .doc(groupId);
        final groupSnapshot = await transaction.get(groupReference);

        if (!groupSnapshot.exists) {
          return FirebaseExceptionConstants.groupDoesNotExist;
        }

        final data = groupSnapshot.data();

        final authorId = data?[GroupModelFieldConstants.authorId];

        final memberIds = List<String>.from(
          (data?[GroupModelFieldConstants.userIds] as List?) ?? [],
        );

        if (authorId != uid) {
          return FirebaseExceptionConstants.groupNonOwnerDeleteMessage;
        }

        for (String memberId in memberIds) {
          final userReference = _database
              .collection(_usersCollection)
              .doc(memberId);
          transaction.update(userReference, {
            UserModelFieldConstants.groupIds: FieldValue.arrayRemove([groupId]),
          });
        }

        transaction.delete(groupReference);

        return FirebaseExceptionConstants.groupDeleteSuccessMessage;
      });
    } catch (_) {
      return FirebaseExceptionConstants.groupDeleteFailedMessage;
    }
  }

  Stream<List<GroupModel>> getUserGroupsStream() {
    final uid = currentUid;

    if (uid == null) {
      return Stream.value([]);
    }

    return _database
        .collection(_groupsCollection)
        .where(GroupModelFieldConstants.userIds, arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromJson(doc.data()))
              .toList(),
        );
  }

  Stream<List<GroupModel>> getAllGroupsStream() {
    return _database
        .collection(_groupsCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                try {
                  return GroupModel.fromJson(doc.data());
                } catch (_) {
                  return null;
                }
              })
              .whereType<GroupModel>()
              .toList(),
        );
  }

  List<GroupModel> filterGroupsLocally({
    required List<GroupModel> groups,
    String? query,
    GroupVisibility? visibilityFilter,
    GroupSortOption sortBy = GroupSortOption.newest,
  }) {
    List<GroupModel> filtered = List.from(groups);

    if (visibilityFilter != null) {
      filtered = filtered
          .where((group) => group.visibility == visibilityFilter)
          .toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final search = query.trim().toLowerCase();
      filtered = filtered
          .where((group) => group.nameLowercase.contains(search))
          .toList();
    }

    switch (sortBy) {
      case GroupSortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case GroupSortOption.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case GroupSortOption.memberCount:
        filtered.sort((a, b) => b.userIds.length.compareTo(a.userIds.length));
        break;
      case GroupSortOption.mostActive:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case GroupSortOption.alphabetical:
        filtered.sort((a, b) => a.nameLowercase.compareTo(b.nameLowercase));
        break;
    }

    return filtered;
  }

  Future<String?> updateGroup(GroupModel group) async {
    try {
      final uid = currentUid;

      if (uid == null) {
        return FirebaseExceptionConstants.userNotLoggedInMessage;
      }

      if (!group.adminIds.contains(uid) && group.authorId != uid) {
        return FirebaseExceptionConstants.groupUpdateNotAuthorMessage;
      }

      final Map<String, dynamic> updateData = group.toJson();

      updateData.remove(GroupModelFieldConstants.userIds);
      updateData.remove(GroupModelFieldConstants.adminIds);
      updateData.remove(GroupModelFieldConstants.editorUserIds);
      updateData.remove(GroupModelFieldConstants.pendingUserRequestIds);
      updateData.remove(GroupModelFieldConstants.testIds);
      updateData.remove(GroupModelFieldConstants.flashcardIds);
      updateData.remove(GroupModelFieldConstants.matchGameIds);

      updateData[GroupModelFieldConstants.updatedAt] =
          FieldValue.serverTimestamp();
      updateData[GroupModelFieldConstants.nameLowercase] = group.name
          .trim()
          .toLowerCase();

      await _database
          .collection(_groupsCollection)
          .doc(group.id)
          .update(updateData);

      return FirebaseExceptionConstants.groupUpdateSuccessMessage;
    } catch (_) {
      return FirebaseExceptionConstants.groupUpdateFailedMessage;
    }
  }
}
