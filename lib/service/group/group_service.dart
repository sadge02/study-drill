import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_drill/models/group/group_model.dart';
import 'package:study_drill/utils/constants/collections/database_constants.dart';
import 'package:study_drill/utils/constants/validator/authentication_validator_constants.dart';

import '../../utils/enums/sorting_type_enum.dart';

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
        return AuthenticationValidatorConstants.userNotLoggedInMessage;
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
        'group_ids': FieldValue.arrayUnion([groupId]),
      });

      await batch.commit();

      return null;
    } catch (_) {
      return AuthenticationValidatorConstants.groupCreateFailedMessage;
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
        return AuthenticationValidatorConstants.userNotLoggedInMessage;
      }

      if (group.userIds.contains(uid)) {
        return AuthenticationValidatorConstants.userAlreadyAMemberMessage;
      }
      if (group.pendingUserRequestIds.contains(uid)) {
        return AuthenticationValidatorConstants.userAlreadyRequestedMessage;
      }

      final groupReference = _database
          .collection(_groupsCollection)
          .doc(group.id);
      final userReference = _database.collection(_usersCollection).doc(uid);

      final batch = _database.batch();

      if (group.visibility == GroupVisibility.public) {
        batch.update(groupReference, {
          'user_ids': FieldValue.arrayUnion([uid]),
          if (group.settings.autoAddAsEditor)
            'editor_user_ids': FieldValue.arrayUnion([uid]),
          'updated_at': FieldValue.serverTimestamp(),
        });

        batch.update(userReference, {
          'group_ids': FieldValue.arrayUnion([group.id]),
        });

        await batch.commit();

        return '${AuthenticationValidatorConstants.userSuccessfullyJoinedMessage} ${group.name}!';
      } else {
        batch.update(groupReference, {
          'pending_user_ids': FieldValue.arrayUnion([uid]),
        });

        await batch.commit();

        return AuthenticationValidatorConstants.userJoinRequestMessage;
      }
    } catch (exception) {
      return '${AuthenticationValidatorConstants.userUnsuccessfullyJoinedMessage}: $exception';
    }
  }

  Future<String?> leaveGroup(String groupId) async {
    try {
      final uid = currentUid;

      if (uid == null) {
        return AuthenticationValidatorConstants.userNotLoggedInMessage;
      }

      return await _database.runTransaction((transaction) async {
        final groupReference = _database
            .collection(_groupsCollection)
            .doc(groupId);
        final userReference = _database.collection(_usersCollection).doc(uid);

        final groupSnapshot = await transaction.get(groupReference);

        if (!groupSnapshot.exists) {
          return AuthenticationValidatorConstants.groupDoesNotExist;
        }

        final data = groupSnapshot.data();

        final authorId = data?['author_id'];

        final userIds = List<String>.from((data?['user_ids'] as List?) ?? []);

        if (uid == authorId) {
          if (userIds.length > 1) {
            return AuthenticationValidatorConstants.groupOwnerLeaveMessage;
          } else {
            transaction.delete(groupReference);
          }
        } else {
          transaction.update(groupReference, {
            'user_ids': FieldValue.arrayRemove([uid]),
            'admin_ids': FieldValue.arrayRemove([uid]),
            'editor_user_ids': FieldValue.arrayRemove([uid]), //
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(userReference, {
          'group_ids': FieldValue.arrayRemove([groupId]),
        });

        return AuthenticationValidatorConstants.groupLeaveSuccessMessage;
      });
    } catch (_) {
      return AuthenticationValidatorConstants.groupLeaveFailedMessage;
    }
  }

  Future<String?> transferOwnership(String groupId, String newAuthorId) async {
    try {
      final uid = currentUid;

      if (uid == null) {
        return AuthenticationValidatorConstants.userNotLoggedInMessage;
      }

      return await _database.runTransaction((transaction) async {
        final groupReference = _database
            .collection(_groupsCollection)
            .doc(groupId);

        final groupSnapshot = await transaction.get(groupReference);

        if (!groupSnapshot.exists) {
          return AuthenticationValidatorConstants.groupDoesNotExist;
        }

        final data = groupSnapshot.data();

        final currentAuthorId = data?['author_id'];

        final userIds = List<String>.from((data?['user_ids'] as List?) ?? []);

        if (uid != currentAuthorId) {
          return AuthenticationValidatorConstants
              .groupNonAuthorTransferOwnershipMessage;
        }

        if (!userIds.contains(newAuthorId)) {
          return AuthenticationValidatorConstants
              .groupNewOwnerMustBeMemberMessage;
        }

        transaction.update(groupReference, {
          'author_id': newAuthorId,
          'admin_ids': FieldValue.arrayUnion([newAuthorId]),
          'updated_at': FieldValue.serverTimestamp(),
        });

        return AuthenticationValidatorConstants
            .groupTransferOwnershipSuccessMessage;
      });
    } catch (_) {
      return AuthenticationValidatorConstants
          .groupTransferOwnershipFailedMessage;
    }
  }

  Future<String?> deleteGroup(String groupId) async {
    try {
      final uid = currentUid;
      if (uid == null) {
        return AuthenticationValidatorConstants.userNotLoggedInMessage;
      }

      return await _database.runTransaction((transaction) async {
        final groupReference = _database
            .collection(_groupsCollection)
            .doc(groupId);
        final groupSnapshot = await transaction.get(groupReference);

        if (!groupSnapshot.exists) {
          return AuthenticationValidatorConstants.groupDoesNotExist;
        }

        final data = groupSnapshot.data();

        final authorId = data?['author_id'];

        final memberIds = List<String>.from((data?['user_ids'] as List?) ?? []);

        if (authorId != uid) {
          return AuthenticationValidatorConstants.groupNonOwnerDeleteMessage;
        }

        for (String memberId in memberIds) {
          final userReference = _database
              .collection(_usersCollection)
              .doc(memberId);
          transaction.update(userReference, {
            'group_ids': FieldValue.arrayRemove([groupId]),
          });
        }

        transaction.delete(groupReference);

        return AuthenticationValidatorConstants.groupDeleteSuccessMessage;
      });
    } catch (_) {
      return AuthenticationValidatorConstants.groupDeleteFailedMessage;
    }
  }

  Stream<List<GroupModel>> getUserGroupsStream() {
    final uid = currentUid;

    if (uid == null) {
      return Stream.value([]);
    }

    return _database
        .collection(_groupsCollection)
        .where('user_ids', arrayContains: uid)
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
      case GroupSortOption.popular:
        filtered.sort((a, b) => b.userIds.length.compareTo(a.userIds.length));
        break;
      case GroupSortOption.alphabetical:
        filtered.sort((a, b) => a.nameLowercase.compareTo(b.nameLowercase));
        break;
      case GroupSortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  Future<String?> updateGroup(GroupModel group) async {
    try {
      final uid = currentUid;

      if (uid == null) {
        return AuthenticationValidatorConstants.userNotLoggedInMessage;
      }

      if (!group.adminIds.contains(uid) && group.authorId != uid) {
        return AuthenticationValidatorConstants.groupUpdateNotAuthorMessage;
      }

      final Map<String, dynamic> updateData = group.toJson();

      updateData.remove('user_ids');
      updateData.remove('admin_ids');
      updateData.remove('editor_user_ids');
      updateData.remove('pending_user_request_ids');
      updateData.remove('test_ids');
      updateData.remove('flashcard_ids');
      updateData.remove('match_game_ids');

      updateData['updated_at'] = FieldValue.serverTimestamp();
      updateData['name_lowercase'] = group.name.trim().toLowerCase();

      await _database
          .collection(_groupsCollection)
          .doc(group.id)
          .update(updateData);

      return AuthenticationValidatorConstants.groupUpdateSuccessMessage;
    } catch (_) {
      return AuthenticationValidatorConstants.groupUpdateFailedMessage;
    }
  }
}
