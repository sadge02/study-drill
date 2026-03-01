import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:study_drill/models/user/user_model.dart';
import 'package:study_drill/utils/constants/collections/database_constants.dart';
import 'package:study_drill/utils/constants/service/user_service_constants.dart';

import '../../utils/constants/error/messages/firebase_exception_constants.dart';
import '../../utils/constants/models/group_model_field_constants.dart';
import '../../utils/constants/models/user_model_field_constants.dart';

class UserService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  static const String _usersCollection = DatabaseConstants.usersCollection;

  String? get currentUid => _authentication.currentUser?.uid;

  CollectionReference<UserModel> get _usersReference => _database
      .collection(_usersCollection)
      .withConverter<UserModel>(
        fromFirestore: (snapshot, _) => UserModel.fromJson(snapshot.data()!),
        toFirestore: (user, _) => user.toJson(),
      );

  Stream<UserModel?> get currentUserStream {
    return _authentication.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value(null);
      }
      return _database
          .collection(_usersCollection)
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists || snapshot.data() == null) {
              return null;
            }
            return UserModel.fromJson(snapshot.data()!);
          });
    });
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersReference.doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Stream<List<UserModel>> searchUsers(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    final searchKey = query.toLowerCase();

    return _database
        .collection(_usersCollection)
        .withConverter<UserModel>(
          fromFirestore: (snapshot, _) => UserModel.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        )
        .where(
          UserModelFieldConstants.usernameLowercase,
          isGreaterThanOrEqualTo: searchKey,
        )
        .where(
          UserModelFieldConstants.usernameLowercase,
          isLessThanOrEqualTo: '$searchKey\uf8ff',
        )
        .orderBy(UserModelFieldConstants.usernameLowercase)
        .limit(UserServiceConstants.userLimit)
        .snapshots()
        .map(
          (querySnapshot) =>
              querySnapshot.docs.map((document) => document.data()).toList(),
        );
  }

  Future<void> updateUser({
    String? username,
    String? summary,
    String? profilePic,
    UserPrivacySettings? privacySettings,
    UserSettings? settings,
    UserTests? statistics,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception(FirebaseExceptionConstants.userNotLoggedInMessage);
    }

    final updates = <String, dynamic>{
      UserModelFieldConstants.updatedAt: DateTime.now().toIso8601String(),
      UserModelFieldConstants.username: ?username,
      if (username != null)
        UserModelFieldConstants.usernameLowercase: username.toLowerCase(),
      UserModelFieldConstants.summary: ?summary,
      UserModelFieldConstants.profilePic: ?profilePic,
      if (privacySettings != null)
        UserModelFieldConstants.privacySettings: privacySettings.toJson(),
      if (settings != null) UserModelFieldConstants.settings: settings.toJson(),
      if (statistics != null)
        UserModelFieldConstants.statistics: statistics.toJson(),
    };

    try {
      await _database.collection(_usersCollection).doc(uid).update(updates);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    final uid = currentUid;

    if (uid == null || uid == targetUserId) {
      return;
    }

    final batch = _database.batch();

    try {
      batch.update(_database.collection(_usersCollection).doc(targetUserId), {
        UserModelFieldConstants.pendingFriendRequestIds: FieldValue.arrayUnion([
          uid,
        ]),
      });

      await batch.commit();
    } catch (_) {}
  }

  Future<void> acceptFriendRequest(String friendId) async {
    final uid = currentUid;
    if (uid == null) {
      return;
    }

    final batch = _database.batch();

    final currentUserDocument = _database.collection(_usersCollection).doc(uid);
    final otherUserDocument = _database
        .collection(_usersCollection)
        .doc(friendId);

    batch.update(currentUserDocument, {
      UserModelFieldConstants.pendingFriendRequestIds: FieldValue.arrayRemove([
        friendId,
      ]),
      UserModelFieldConstants.friendIds: FieldValue.arrayUnion([friendId]),
    });
    batch.update(otherUserDocument, {
      UserModelFieldConstants.friendIds: FieldValue.arrayUnion([uid]),
      UserModelFieldConstants.sentFriendRequestIds: FieldValue.arrayRemove([
        uid,
      ]),
    });

    await batch.commit();
  }

  Future<void> deleteUserAccount() async {
    final uid = currentUid;

    if (uid == null) {
      throw Exception(FirebaseExceptionConstants.userNotLoggedInMessage);
    }

    final ownedGroupsQuery = await _database
        .collection(DatabaseConstants.groupsCollection)
        .where(GroupModelFieldConstants.authorId, isEqualTo: uid)
        .get();

    if (ownedGroupsQuery.docs.isNotEmpty) {
      ownedGroupsQuery.docs
          .map(
            (document) =>
                document.data()[GroupModelFieldConstants.name] as String,
          )
          .toList();

      throw Exception(
        FirebaseExceptionConstants.userDeleteAccountConditionsMessage,
      );
    }

    final userDocument = await _usersReference.doc(uid).get();
    final userData = userDocument.data();

    if (userData == null) {
      return;
    }

    final batch = _database.batch();

    final usernameReference = _database
        .collection(DatabaseConstants.usernamesCollection)
        .doc(userData.usernameLowercase);
    batch.delete(usernameReference);

    for (String groupId in userData.groupIds) {
      final groupReference = _database
          .collection(DatabaseConstants.groupsCollection)
          .doc(groupId);
      batch.update(groupReference, {
        GroupModelFieldConstants.userIds: FieldValue.arrayRemove([uid]),
        GroupModelFieldConstants.adminIds: FieldValue.arrayRemove([uid]),
        GroupModelFieldConstants.editorUserIds: FieldValue.arrayRemove([uid]),
      });
    }

    batch.delete(_database.collection(_usersCollection).doc(uid));

    try {
      await batch.commit();

      await _authentication.currentUser?.delete();
    } catch (_) {
      rethrow;
    }
  }
}
