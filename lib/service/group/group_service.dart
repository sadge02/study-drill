import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_drill/models/group/group_model.dart'; // Adjust path

class GroupService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  CollectionReference get _groupsRef => _database.collection('groups');

  CollectionReference get _usersRef => _database.collection('users');

  Future<String?> createGroup({
    required String name,
    required String summary,
    required String profilePic,
    required GroupVisibility visibility,
    required GroupSettings settings,
    List<String> tags = const [],
  }) async {
    try {
      final String? userId = _authentication.currentUser?.uid;

      if (userId == null) {
        return 'You must be logged in to create a group.';
      }

      final DocumentReference newGroupDoc = _groupsRef.doc();

      final String groupId = newGroupDoc.id;

      final GroupModel newGroup = GroupModel(
        id: groupId,
        name: name,
        summary: summary,
        profilePic: profilePic,
        authorId: userId,
        visibility: visibility,
        settings: settings,
        tags: tags,
        userIds: [userId],
        adminIds: [userId],
        editorUserIds: [userId],
        createdAt: DateTime.now(),
      );

      final WriteBatch batch = _database.batch();

      batch.set(newGroupDoc, newGroup.toJson());

      final DocumentReference userDoc = _usersRef.doc(userId);
      batch.update(userDoc, {
        'group_ids': FieldValue.arrayUnion([groupId]),
      });
      await batch.commit();
      return null;
    } catch (exception) {
      return 'Failed to create group: $exception';
    }
  }

  Future<String?> updateGroup(GroupModel group) async {
    try {
      await _database.collection('groups').doc(group.id).update(group.toJson());
      return null;
    } catch (e) {
      return 'Update failed: $e';
    }
  }

  Future<String?> joinGroup(GroupModel group) async {
    try {
      final String? userId = _authentication.currentUser?.uid;
      if (userId == null) {
        return 'You must be logged in.';
      }

      if (group.userIds.contains(userId)) {
        return 'You are already a member.';
      }

      final DocumentReference groupDocument = _groupsRef.doc(group.id);
      final DocumentReference userDocument = _usersRef.doc(userId);
      final WriteBatch batch = _database.batch();

      if (group.visibility == GroupVisibility.public) {
        batch.update(groupDocument, {
          'user_ids': FieldValue.arrayUnion([userId]),
        });
        if (group.settings?.autoAddAsEditor == true) {
          batch.update(groupDocument, {
            'editor_user_ids': FieldValue.arrayUnion([userId]),
          });
        }

        batch.update(userDocument, {
          'group_ids': FieldValue.arrayUnion([group.id]),
        });
        await batch.commit();
        return 'Successfully joined ${group.name}!';
      } else {
        if (group.pendingUserIds.contains(userId)) {
          return 'You have already requested to join this group.';
        }
        await groupDocument.update({
          'pending_user_ids': FieldValue.arrayUnion([userId]),
        });
        return 'Join request sent to ${group.name}.';
      }
    } catch (exception) {
      return 'Error joining group: $exception';
    }
  }

  Future<String?> approveJoinRequest({
    required GroupModel group,
    required String requestingUserId,
  }) async {
    try {
      final String? currentUserId = _authentication.currentUser?.uid;
      if (currentUserId == null || !group.adminIds.contains(currentUserId)) {
        return 'You do not have permission to approve requests.';
      }

      final WriteBatch batch = _database.batch();
      final DocumentReference groupDocument = _groupsRef.doc(group.id);
      final DocumentReference userDocument = _usersRef.doc(requestingUserId);

      batch.update(groupDocument, {
        'pending_user_ids': FieldValue.arrayRemove([requestingUserId]),
        'user_ids': FieldValue.arrayUnion([requestingUserId]),
      });

      if (group.settings?.autoAddAsEditor == true) {
        batch.update(groupDocument, {
          'editor_user_ids': FieldValue.arrayUnion([requestingUserId]),
        });
      }

      batch.update(userDocument, {
        'group_ids': FieldValue.arrayUnion([group.id]),
      });
      await batch.commit();
      return null;
    } catch (exception) {
      return 'Failed to approve request: $exception';
    }
  }

  Future<String?> leaveGroup(String groupId) async {
    try {
      final String? userId = _authentication.currentUser?.uid;
      if (userId == null) {
        return 'You must be logged in.';
      }

      final WriteBatch batch = _database.batch();

      batch.update(_groupsRef.doc(groupId), {
        'user_ids': FieldValue.arrayRemove([userId]),
        'admin_ids': FieldValue.arrayRemove([userId]),
        'editor_user_ids': FieldValue.arrayRemove([userId]),
        'pending_user_ids': FieldValue.arrayRemove([userId]),
      });

      batch.update(_usersRef.doc(userId), {
        'group_ids': FieldValue.arrayRemove([groupId]),
      });
      await batch.commit();
      return null;
    } catch (exception) {
      return 'Error leaving group: $exception';
    }
  }

  Stream<GroupModel?> getGroupStream(String groupId) {
    return _groupsRef.doc(groupId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return GroupModel.fromJson(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Stream<List<GroupModel>> getUserGroupsStream() {
    final String? userId = _authentication.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    return _groupsRef
        .where('user_ids', arrayContains: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return GroupModel.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  Future<String?> promoteToEditor({
    required String groupId,
    required String targetUserId,
  }) async {
    try {
      final String? currentUserId = _authentication.currentUser?.uid;
      if (currentUserId == null) {
        return 'Must be logged in';
      }

      final docSnapshot = await _groupsRef.doc(groupId).get();

      final groupData = docSnapshot.data() as Map<String, dynamic>?;

      if (groupData == null ||
          !(groupData['admin_ids'] as List).contains(currentUserId)) {
        return 'You do not have permission.';
      }

      await _groupsRef.doc(groupId).update({
        'editor_user_ids': FieldValue.arrayUnion([targetUserId]),
      });
      return null;
    } catch (exception) {
      return 'Failed to promote user: $exception';
    }
  }
}
