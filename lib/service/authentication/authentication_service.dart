import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:study_drill/utils/validators/authentication/authentication_validator.dart';

import '../../../models/user/user_model.dart';

class AuthenticationService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  Future<bool> isUsernameTaken(String username) async {
    final doc = await _database.collection('usernames').doc(username).get();
    return doc.exists;
  }

  Future<bool> isEmailTaken(String email) async {
    try {
      final result = await _database
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return result.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    String? profilePicUrl,
  }) async {
    try {
      final userError = AuthenticationValidator.validateUsername(username);
      if (userError != null) {
        return userError;
      }

      final emailError = AuthenticationValidator.validateEmail(email);
      if (emailError != null) {
        return emailError;
      }

      final passwordError = AuthenticationValidator.validatePassword(password);
      if (passwordError != null) {
        return passwordError;
      }

      if (await isUsernameTaken(username)) {
        return 'Username is already taken. Please choose another one.';
      }

      if (await isEmailTaken(email)) {
        return 'This email is already registered. Try logging in.';
      }

      final UserCredential credentials = await _authentication
          .createUserWithEmailAndPassword(email: email, password: password);

      final String id = credentials.user!.uid;
      final String profilePic =
          profilePicUrl ??
          'https://ui-avatars.com/api/?name=$username&background=6096B4&color=fff';

      await credentials.user?.updateDisplayName(username);
      await credentials.user?.updatePhotoURL(profilePic);

      final UserModel user = UserModel(
        id: id,
        email: email,
        username: username,
        summary: '',
        profilePic: profilePic,
        createdAt: DateTime.now(),
        groupIds: [],
        friendIds: [],
        statistics: UserTests(userTests: {}),

        privacySettings: UserPrivacySettings(
          email: UserVisibility.private,
          statistics: UserVisibility.public,
          groups: UserVisibility.public,
          tests: UserVisibility.public,
        ),
      );

      final WriteBatch batch = _database.batch();

      batch.set(_database.collection('users').doc(id), user.toJson());

      batch.set(_database.collection('usernames').doc(username), {'uid': id});

      await batch.commit();

      return null;
    } on FirebaseAuthException catch (exception) {
      return exception.message;
    } catch (_) {
      return 'An unknown error occurred.';
    }
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _authentication.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (exception) {
      return exception.message;
    }
  }

  Future<void> logout() async {
    await _authentication.signOut();
  }
}
