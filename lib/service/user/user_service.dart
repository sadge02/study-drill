import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:study_drill/models/user/user_model.dart';
import 'package:study_drill/utils/constants/collections/database_constants.dart';
import 'package:study_drill/utils/constants/service/user_service_constants.dart';
import 'package:study_drill/utils/constants/validator/authentication_validator_constants.dart';

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
        .where('username_lowercase', isGreaterThanOrEqualTo: searchKey)
        .where('username_lowercase', isLessThanOrEqualTo: '$searchKey\uf8ff')
        .orderBy('username_lowercase')
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
      throw Exception(AuthenticationValidatorConstants.userNotLoggedInMessage);
    }

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      'username': ?username,
      if (username != null) 'username_lowercase': username.toLowerCase(),
      'summary': ?summary,
      'profile_pic': ?profilePic,
      if (privacySettings != null) 'privacy_settings': privacySettings.toJson(),
      if (settings != null) 'settings': settings.toJson(),
      if (statistics != null) 'statistics': statistics.toJson(),
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
        'pending_friend_request_ids': FieldValue.arrayUnion([uid]),
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
      'pending_friend_request_ids': FieldValue.arrayRemove([friendId]),
      'friend_ids': FieldValue.arrayUnion([friendId]),
    });
    batch.update(otherUserDocument, {
      'friend_ids': FieldValue.arrayUnion([uid]),
      'sent_friend_request_ids': FieldValue.arrayRemove([uid]),
    });

    await batch.commit();
  }

  Future<void> deleteUserAccount() async {
    final uid = currentUid;

    if (uid == null) {
      throw Exception(AuthenticationValidatorConstants.userNotLoggedInMessage);
    }

    final ownedGroupsQuery = await _database
        .collection(DatabaseConstants.groupsCollection)
        .where('author_id', isEqualTo: uid)
        .get();

    if (ownedGroupsQuery.docs.isNotEmpty) {
      ownedGroupsQuery.docs
          .map((document) => document.data()['name'] as String)
          .toList();

      throw Exception(
        AuthenticationValidatorConstants.userDeleteAccountConditionsMessage,
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
        'user_ids': FieldValue.arrayRemove([uid]),
        'admin_ids': FieldValue.arrayRemove([uid]),
        'editor_user_ids': FieldValue.arrayRemove([uid]),
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
