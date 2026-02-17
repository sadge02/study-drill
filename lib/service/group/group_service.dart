import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:study_drill/models/group/group_model.dart';

class GroupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Collection Constants
  static const String _gCollection = 'groups';
  static const String _uCollection = 'users';

  String? get currentUid => _auth.currentUser?.uid;

  /// 1. CREATE GROUP
  /// Uses an atomic batch to create the group and update the creator's user document.
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
      if (uid == null) return 'You must be logged in.';

      final groupDoc = _db.collection(_gCollection).doc();
      final groupId = groupDoc.id;

      final group = GroupModel(
        id: groupId,
        name: name.trim(),
        nameLowercase: name.trim().toLowerCase(), // Enhancement: For search
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
        updatedAt: DateTime.now(), // Enhancement: Timestamp
      );

      final WriteBatch batch = _db.batch();
      batch.set(groupDoc, group.toJson());
      batch.update(_db.collection(_uCollection).doc(uid), {
        'group_ids': FieldValue.arrayUnion([groupId]),
      });

      await batch.commit();

      // Subscribe to group topic for notifications outside the app
      await _fcm.subscribeToTopic('group_$groupId');

      return null;
    } catch (e) {
      debugPrint('Create Group Error: $e');
      return 'Failed to create group.';
    }
  }

  /// 2. JOIN GROUP
  /// Handles public auto-join vs private join requests.
  Future<String?> joinGroup(GroupModel group) async {
    try {
      final uid = currentUid;
      if (uid == null) return 'You must be logged in.';

      if (group.userIds.contains(uid)) return 'Already a member.';
      if (group.pendingUserRequestIds.contains(uid))
        return 'Request already pending.';

      final groupRef = _db.collection(_gCollection).doc(group.id);

      if (group.visibility == GroupVisibility.public) {
        final batch = _db.batch();

        batch.update(groupRef, {
          'user_ids': FieldValue.arrayUnion([uid]),
          if (group.settings.autoAddAsEditor)
            'editor_user_ids': FieldValue.arrayUnion([uid]),
          'updated_at': DateTime.now().toIso8601String(),
        });

        batch.update(_db.collection(_uCollection).doc(uid), {
          'group_ids': FieldValue.arrayUnion([group.id]),
        });

        await batch.commit();
        await _fcm.subscribeToTopic('group_${group.id}');
        return 'Successfully joined ${group.name}!';
      } else {
        // Private Group: Send request
        await groupRef.update({
          'pending_user_ids': FieldValue.arrayUnion([uid]),
        });
        return 'Join request sent.';
      }
    } catch (e) {
      return 'Join failed: $e';
    }
  }

  /// 3. LEAVE GROUP
  Future<String?> leaveGroup(String groupId) async {
    try {
      final uid = currentUid;
      if (uid == null) return 'Login required.';

      final batch = _db.batch();
      batch.update(_db.collection(_gCollection).doc(groupId), {
        'user_ids': FieldValue.arrayRemove([uid]),
        'admin_ids': FieldValue.arrayRemove([uid]),
        'editor_user_ids': FieldValue.arrayRemove([uid]),
        'pending_user_ids': FieldValue.arrayRemove([uid]),
      });

      batch.update(_db.collection(_uCollection).doc(uid), {
        'group_ids': FieldValue.arrayRemove([groupId]),
      });

      await batch.commit();
      await _fcm.unsubscribeFromTopic('group_$groupId');
      return null;
    } catch (e) {
      return 'Leave failed: $e';
    }
  }

  /// 4. EFFICIENT DATABASE SEARCH
  /// Uses the name_lowercase field to perform starts-with queries on the server.
  Stream<List<GroupModel>> searchGroupsOnServer(String query) {
    if (query.trim().isEmpty) return Stream.value([]);

    final searchKey = query.trim().toLowerCase();

    return _db
        .collection(_gCollection)
        .where('visibility', isEqualTo: 'public')
        .where('name_lowercase', isGreaterThanOrEqualTo: searchKey)
        .where('name_lowercase', isLessThanOrEqualTo: '$searchKey\uf8ff')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => GroupModel.fromJson(doc.data())).toList(),
        );
  }

  /// 5. LOCAL FILTER & SORT
  /// This remains for filtering data already downloaded to the phone.
  List<GroupModel> filterGroupsLocally({
    required List<GroupModel> groups,
    String? query,
    String sortBy = 'newest',
  }) {
    List<GroupModel> filtered = List.from(groups);

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((g) => g.nameLowercase.contains(q)).toList();
    }

    switch (sortBy) {
      case 'popular':
        filtered.sort((a, b) => b.memberCount.compareTo(a.memberCount));
        break;
      case 'alpha':
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      default: // newest
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return filtered;
  }

  // --- STREAMS ---

  Stream<GroupModel?> getGroupStream(String groupId) => _db
      .collection(_gCollection)
      .doc(groupId)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.exists ? GroupModel.fromJson(snapshot.data()!) : null,
      );

  Stream<List<GroupModel>> getUserGroupsStream() {
    final uid = currentUid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection(_gCollection)
        .where('user_ids', arrayContains: uid)
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => GroupModel.fromJson(doc.data())).toList(),
        );
  }
}
