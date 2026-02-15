import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_drill/models/user/user_model.dart';

class UserService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  String? get currentUid => _authentication.currentUser?.uid;

  Stream<UserModel?> get currentUserStream {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(null);
    }
    return _database.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserModel.fromJson(snapshot.data()!);
    });
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final document = await _database.collection('users').doc(uid).get();
      if (!document.exists || document.data() == null) {
        return null;
      }
      return UserModel.fromJson(document.data()!);
    } catch (_) {
      return null;
    }
  }

  Stream<List<UserModel>> searchUsers(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }
    return _database
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => UserModel.fromJson(document.data()))
              .toList(),
        );
  }

  Future<void> updateUser({
    String? username,
    String? summary,
    String? profilePic,
    UserPrivacySettings? privacySettings,
    UserSettings? settings,
    List<String>? groupIds,
    List<String>? friendIds,
    UserTests? statistics,
  }) async {
    try {
      final uid = currentUid;

      if (uid == null) {
        throw Exception('You must be logged in.');
      }

      final Map<String, dynamic> updates = {};

      if (username != null) {
        updates['username'] = username;
      }

      if (summary != null) {
        updates['summary'] = summary;
      }

      if (profilePic != null) {
        updates['profile_pic'] = profilePic;
      }

      if (privacySettings != null) {
        updates['privacy_settings'] = privacySettings.toJson();
      }

      if (settings != null) {
        updates['settings'] = settings.toJson();
      }

      if (statistics != null) {
        updates['statistics'] = statistics.toJson();
      }

      if (groupIds != null) {
        updates['group_ids'] = groupIds;
      }

      if (friendIds != null) {
        updates['friend_ids'] = friendIds;
      }

      if (updates.isNotEmpty) {
        await _database.collection('users').doc(uid).update(updates);
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<void> addFriend(String friendId) async {
    final uid = currentUid;

    if (uid == null) {
      throw Exception('You must be logged in.');
    }

    await _database.collection('users').doc(uid).update({
      'friend_ids': FieldValue.arrayUnion([friendId]),
    });
  }
}
