import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/group/group_model.dart';
import '../../models/user/user_model.dart';
import '../../utils/constants/collections/database_constants.dart';
import '../../utils/constants/error/messages/firebase_exception_constants.dart';
import '../../utils/constants/models/group/group_model_field_constants.dart';
import '../../utils/constants/models/user/user_model_field_constants.dart';

class UserService {
  final FirebaseFirestore _database = FirebaseFirestore.instance;
  final FirebaseAuth _authentication = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _userCollection =>
      _database.collection(DatabaseConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _usernameCollection =>
      _database.collection(DatabaseConstants.usernamesCollection);

  CollectionReference<Map<String, dynamic>> get _groupCollection =>
      _database.collection(DatabaseConstants.groupsCollection);

  CollectionReference<Map<String, dynamic>> get _testCollection =>
      _database.collection(DatabaseConstants.testsCollection);

  CollectionReference<Map<String, dynamic>> get _flashcardCollection =>
      _database.collection(DatabaseConstants.flashcardsCollection);

  CollectionReference<Map<String, dynamic>> get _connectCollection =>
      _database.collection(DatabaseConstants.connectsCollection);

  /// --------------------------------------------------------------------------
  /// READ
  /// --------------------------------------------------------------------------

  /// Fetches a single user by their [userId].
  Future<UserModel?> getUserById(String userId) async {
    final document = await _userCollection.doc(userId).get();
    if (!document.exists || document.data() == null) {
      return null;
    }
    return UserModel.fromJson(document.data()!);
  }

  /// Returns a real-time stream of a single user.
  Stream<UserModel?> streamUserById(String userId) {
    return _userCollection.doc(userId).snapshots().map((document) {
      if (!document.exists || document.data() == null) {
        return null;
      }
      return UserModel.fromJson(document.data()!);
    });
  }

  /// Fetches the currently authenticated user's document.
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _authentication.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    return getUserById(firebaseUser.uid);
  }

  /// Returns a real-time stream of the currently authenticated user's document.
  Stream<UserModel?> streamCurrentUser() {
    final firebaseUser = _authentication.currentUser;
    if (firebaseUser == null) {
      return Stream.value(null);
    }
    return streamUserById(firebaseUser.uid);
  }

  /// Fetches every user document in the collection.
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _userCollection.get();
    return snapshot.docs
        .map((document) => UserModel.fromJson(document.data()))
        .toList();
  }

  /// Returns a real-time stream of every user document.
  Stream<List<UserModel>> streamAllUsers() {
    return _userCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((document) => UserModel.fromJson(document.data()))
          .toList(),
    );
  }

  /// Fetches a user by their username.
  Future<UserModel?> getUserByUsername(String username) async {
    final usernameDocument = await _usernameCollection
        .doc(username.trim().toLowerCase())
        .get();
    if (!usernameDocument.exists || usernameDocument.data() == null) {
      return null;
    }
    final uid = usernameDocument.data()!['uid'] as String;
    return getUserById(uid);
  }

  /// Fetches a user by their email address.
  Future<UserModel?> getUserByEmail(String email) async {
    final snapshot = await _userCollection
        .where(UserModelFieldConstants.email, isEqualTo: email.trim())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return UserModel.fromJson(snapshot.docs.first.data());
  }

  /// Fetches all groups the given user is a member of.
  Future<List<GroupModel>> getUserGroups(String userId) async {
    final user = await getUserById(userId);
    if (user == null || user.groupIds.isEmpty) {
      return [];
    }

    final List<GroupModel> groups = [];
    final chunks = _chunkList(
      user.groupIds,
      GroupModelFieldConstants.whereInLimit,
    );

    for (final chunk in chunks) {
      final snapshot = await _groupCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      groups.addAll(
        snapshot.docs.map((document) => GroupModel.fromJson(document.data())),
      );
    }

    return groups;
  }

  /// Returns a real-time stream of all groups the given user is a member of.
  Stream<List<GroupModel>> streamUserGroups(String userId) {
    return streamUserById(userId).asyncMap((user) async {
      if (user == null || user.groupIds.isEmpty) {
        return <GroupModel>[];
      }

      final List<GroupModel> groups = [];
      final chunks = _chunkList(
        user.groupIds,
        GroupModelFieldConstants.whereInLimit,
      );

      for (final chunk in chunks) {
        final snapshot = await _groupCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        groups.addAll(
          snapshot.docs.map((document) => GroupModel.fromJson(document.data())),
        );
      }

      return groups;
    });
  }

  /// Fetches multiple users by their IDs.
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return [];
    }

    final List<UserModel> users = [];
    final chunks = _chunkList(userIds, GroupModelFieldConstants.whereInLimit);

    for (final chunk in chunks) {
      final snapshot = await _userCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(
        snapshot.docs.map((document) => UserModel.fromJson(document.data())),
      );
    }

    return users;
  }

  /// Fetches all friends of the given user.
  Future<List<UserModel>> getFriends(String userId) async {
    final user = await getUserById(userId);
    if (user == null) {
      return [];
    }
    return getUsersByIds(user.friendIds);
  }

  /// Returns a real-time stream of the given user's friend list.
  Stream<List<UserModel>> streamFriends(String userId) {
    return streamUserById(userId).asyncMap((user) async {
      if (user == null) {
        return [];
      }
      return getUsersByIds(user.friendIds);
    });
  }

  /// --------------------------------------------------------------------------
  /// UPDATE
  /// --------------------------------------------------------------------------

  /// Updates the user document with the provided [user].
  Future<String?> updateUser(UserModel user) async {
    try {
      await _userCollection.doc(user.id).set(user.toJson());
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.userUpdateFailedMessage;
    }
  }

  /// --------------------------------------------------------------------------
  /// FRIEND MANAGEMENT
  /// --------------------------------------------------------------------------

  /// Add a friend.
  Future<String?> addFriend(String userId, String friendId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        return FirebaseExceptionConstants.userNotFoundMessage;
      }

      if (user.friendIds.contains(friendId)) {
        return FirebaseExceptionConstants.userAlreadyFriendsMessage;
      }

      final batch = _database.batch();

      batch.update(_userCollection.doc(userId), {
        UserModelFieldConstants.friendIds: FieldValue.arrayUnion([friendId]),
        UserModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });

      batch.update(_userCollection.doc(friendId), {
        UserModelFieldConstants.friendIds: FieldValue.arrayUnion([userId]),
        UserModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });

      await batch.commit();
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.userFriendRequestFailedMessage;
    }
  }

  /// Removes a friend.
  Future<String?> removeFriend(String userId, String friendId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        return FirebaseExceptionConstants.userNotFoundMessage;
      }

      if (!user.friendIds.contains(friendId)) {
        return FirebaseExceptionConstants.userNotFriendsMessage;
      }

      final batch = _database.batch();

      batch.update(_userCollection.doc(userId), {
        UserModelFieldConstants.friendIds: FieldValue.arrayRemove([friendId]),
        UserModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });

      batch.update(_userCollection.doc(friendId), {
        UserModelFieldConstants.friendIds: FieldValue.arrayRemove([userId]),
        UserModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      });

      await batch.commit();
      return null;
    } catch (_) {
      return FirebaseExceptionConstants.userRemoveFriendFailedMessage;
    }
  }

  /// --------------------------------------------------------------------------
  /// STATISTICS
  /// --------------------------------------------------------------------------

  /// Adds a statistics entry for a specific group.
  Future<void> addStatisticsEntry(
    String userId,
    String groupId,
    UserStatisticsEntry entry,
  ) async {
    await _userCollection.doc(userId).update({
      '${UserModelFieldConstants.statistics}.$groupId': FieldValue.arrayUnion([
        entry.toJson(),
      ]),
    });
  }

  /// --------------------------------------------------------------------------
  /// DELETE
  /// --------------------------------------------------------------------------

  /// Deletes a user account and all transitive dependencies.
  ///
  /// The user must not be the author of any group. If they are, they must
  /// transfer ownership or delete those groups first.
  ///
  /// Steps performed:
  /// 1. Block deletion if the user owns any groups.
  /// 2. Remove the user from all groups (userIds, adminIds, creatorIds) and
  ///    remove any join requests they submitted.
  /// 3. Remove the user from every friend's friendIds.
  /// 4. Remove any UserRequests referencing this user from other users.
  /// 5. Delete the username reservation document.
  /// 6. Delete the user document.
  /// 7. Delete the Firebase Auth account.
  Future<String?> deleteUser(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        return FirebaseExceptionConstants.userNotFoundMessage;
      }

      final ownedGroups = await _groupCollection
          .where(GroupModelFieldConstants.authorId, isEqualTo: userId)
          .get();

      if (ownedGroups.docs.isNotEmpty) {
        return FirebaseExceptionConstants.userDeleteAccountConditionsMessage;
      }

      WriteBatch batch = _database.batch();
      int operationCount = 0;

      Future<void> commitIfNeeded() async {
        if (operationCount >= GroupModelFieldConstants.batchLimit) {
          await batch.commit();
          batch = _database.batch();
          operationCount = 0;
        }
      }

      for (final groupId in user.groupIds) {
        batch.update(_groupCollection.doc(groupId), {
          GroupModelFieldConstants.userIds: FieldValue.arrayRemove([userId]),
          GroupModelFieldConstants.adminIds: FieldValue.arrayRemove([userId]),
          GroupModelFieldConstants.creatorIds: FieldValue.arrayRemove([userId]),
          GroupModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
        });
        operationCount++;
        await commitIfNeeded();
      }

      final groupsWithJoinRequests = await _groupCollection.get();
      for (final groupDoc in groupsWithJoinRequests.docs) {
        final rawRequests =
            groupDoc.data()[GroupModelFieldConstants.joinRequests]
                as List<dynamic>? ??
            [];
        final matching = rawRequests
            .cast<Map<String, dynamic>>()
            .where(
              (r) => r[GroupModelFieldConstants.joinRequestUserId] == userId,
            )
            .toList();
        for (final request in matching) {
          batch.update(groupDoc.reference, {
            GroupModelFieldConstants.joinRequests: FieldValue.arrayRemove([
              request,
            ]),
          });
          operationCount++;
          await commitIfNeeded();
        }
      }

      for (final friendId in user.friendIds) {
        batch.update(_userCollection.doc(friendId), {
          UserModelFieldConstants.friendIds: FieldValue.arrayRemove([userId]),
          UserModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
        });
        operationCount++;
        await commitIfNeeded();
      }

      final Set<String> usersWithRequests = {};
      for (final request in user.requests) {
        final otherUserId = request.fromUserId == userId
            ? request.toUserId
            : request.fromUserId;
        usersWithRequests.add(otherUserId);
      }

      for (final otherUserId in usersWithRequests) {
        final otherDoc = await _userCollection.doc(otherUserId).get();
        if (otherDoc.exists && otherDoc.data() != null) {
          final rawRequests =
              otherDoc.data()![UserModelFieldConstants.requests]
                  as List<dynamic>? ??
              [];
          final filtered = rawRequests
              .cast<Map<String, dynamic>>()
              .where(
                (r) =>
                    r[UserModelFieldConstants.requestFromUserId] != userId &&
                    r[UserModelFieldConstants.requestToUserId] != userId,
              )
              .toList();
          if (filtered.length != rawRequests.length) {
            batch.update(_userCollection.doc(otherUserId), {
              UserModelFieldConstants.requests: filtered,
            });
            operationCount++;
            await commitIfNeeded();
          }
        }
      }

      batch.delete(_usernameCollection.doc(user.username.toLowerCase()));
      operationCount++;
      await commitIfNeeded();

      batch.delete(_userCollection.doc(userId));
      operationCount++;

      await batch.commit();

      final firebaseUser = _authentication.currentUser;
      if (firebaseUser != null && firebaseUser.uid == userId) {
        await firebaseUser.delete();
      }

      return null;
    } catch (_) {
      return FirebaseExceptionConstants.userDeleteFailedMessage;
    }
  }

  /// --------------------------------------------------------------------------
  /// HELPERS
  /// --------------------------------------------------------------------------

  /// Splits a list into chunks of the given [size] (for Firestore `whereIn`
  /// which is limited to 10 elements).
  List<List<T>> _chunkList<T>(List<T> list, int size) {
    final List<List<T>> chunks = [];
    for (int i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }
}
