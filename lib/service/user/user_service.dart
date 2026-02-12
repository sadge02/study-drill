import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_drill/models/user/user_model.dart';

class UserService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  String? get currentUid => _authentication.currentUser?.uid;

  Stream<UserModel?> get currentUserStream {
    if (currentUid == null) {
      return Stream.value(null);
    }
    return _database.collection('users').doc(currentUid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return null;
      }
      return UserModel.fromJson(snapshot.data()!);
    });
  }

  Future<UserModel?> getUserById(String uid) async {
    final document = await _database.collection('users').doc(uid).get();
    if (!document.exists) {
      return null;
    }
    return UserModel.fromJson(document.data()!);
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

  Future<void> updateProfile({
    String? username,
    String? summary,
    String? profilePic,
    UserPrivacySettings? privacySettings,
    List<String>? groupIds,
    List<String>? friendIds,
    UserTests? statistics,
  }) async {
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
      await _database.collection('users').doc(currentUid).update(updates);
    }
  }
}
