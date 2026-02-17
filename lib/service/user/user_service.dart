import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:study_drill/models/user/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Collection Constants
  static const String _uCollection = 'users';

  String? get currentUid => _auth.currentUser?.uid;

  /// 1. REAL-TIME USER DATA
  Stream<UserModel?> get currentUserStream {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);

    return _db.collection(_uCollection).doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromJson(snapshot.data()!);
    });
  }

  /// 2. FETCH USER BY ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _db.collection(_uCollection).doc(uid).get();
      return doc.exists ? UserModel.fromJson(doc.data()!) : null;
    } catch (e) {
      debugPrint('Error fetching user $uid: $e');
      return null;
    }
  }

  /// 3. SERVER-SIDE SEARCH (Case-Insensitive)
  /// Uses the username_lowercase field for efficient "starts with" querying.
  Stream<List<UserModel>> searchUsers(String query) {
    if (query.trim().isEmpty) return Stream.value([]);

    final searchKey = query.trim().toLowerCase();

    return _db
        .collection(_uCollection)
        .where('username_lowercase', isGreaterThanOrEqualTo: searchKey)
        .where('username_lowercase', isLessThanOrEqualTo: '$searchKey\uf8ff')
        .limit(20) // Limit results for performance
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => UserModel.fromJson(doc.data())).toList(),
        );
  }

  /// 4. UPDATE USER PROFILE
  /// Automatically manages username_lowercase and updatedAt.
  Future<void> updateUser({
    String? username,
    String? summary,
    String? profilePic,
    UserPrivacySettings? privacySettings,
    UserSettings? settings,
    UserTests? statistics,
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('User not logged in.');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(), // Always update timestamp
      if (username != null) 'username': username.trim(),
      if (username != null) 'username_lowercase': username.trim().toLowerCase(),
      if (summary != null) 'summary': summary,
      if (profilePic != null) 'profile_pic': profilePic,
      if (privacySettings != null) 'privacy_settings': privacySettings.toJson(),
      if (settings != null) 'settings': settings.toJson(),
      if (statistics != null) 'statistics': statistics.toJson(),
    };

    try {
      await _db.collection(_uCollection).doc(uid).update(updates);
    } catch (e) {
      debugPrint('Update Error: $e');
      rethrow;
    }
  }

  /// 5. MANAGE FCM TOKEN (Notifications Outside App)
  /// Should be called on app startup or when the token refreshes.
  Future<void> updateFcmToken() async {
    final uid = currentUid;
    if (uid == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _db.collection(_uCollection).doc(uid).update({
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('FCM Token Update Error: $e');
    }
  }

  /// 6. FRIENDSHIP MANAGEMENT
  /// Uses a WriteBatch to handle friend requests (Pending state).
  Future<void> sendFriendRequest(String targetUserId) async {
    final uid = currentUid;
    if (uid == null) return;

    try {
      // Add current user's ID to the target user's pending list
      await _db.collection(_uCollection).doc(targetUserId).update({
        'pending_friend_request_ids': FieldValue.arrayUnion([uid]),
      });

      // Note: In a full system, you'd send a push notification here
      // to the targetUserId using their fcm_token.
    } catch (e) {
      debugPrint('Friend Request Error: $e');
    }
  }

  Future<void> acceptFriendRequest(String friendId) async {
    final uid = currentUid;
    if (uid == null) return;

    final batch = _db.batch();

    // 1. Move friendId from pending to friend_ids for CURRENT user
    batch.update(_db.collection(_uCollection).doc(uid), {
      'pending_friend_request_ids': FieldValue.arrayRemove([friendId]),
      'friend_ids': FieldValue.arrayUnion([friendId]),
    });

    // 2. Add current user to TARGET user's friend_ids
    batch.update(_db.collection(_uCollection).doc(friendId), {
      'friend_ids': FieldValue.arrayUnion([uid]),
    });

    await batch.commit();
  }
}
