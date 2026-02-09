import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _authInstance = FirebaseAuth.instance;
  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;

  Future<bool> isUsernameTaken(String username) async {
    final result = await _firestoreInstance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<bool> isEmailTaken(String email) async {
    final result = await _firestoreInstance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    String? profilePicUrl,
  }) async {
    try {
      if (await isUsernameTaken(username)) {
        return 'Username is already taken. Please choose another one.';
      }

      if (await isEmailTaken(email)) {
        return 'This email is already registered. Try logging in!';
      }

      final UserCredential cred = await _authInstance
          .createUserWithEmailAndPassword(email: email, password: password);

      await cred.user?.updatePhotoURL(
        profilePicUrl ??
            'https://ui-avatars.com/api/?name=$username&background=6096B4&color=fff',
      );

      await _firestoreInstance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'username': username,
        'email': email,
        'profilePic':
            profilePicUrl ??
            'https://ui-avatars.com/api/?name=$username&background=6096B4&color=fff',
        'createdAt': FieldValue.serverTimestamp(),
        'groupIds': <String>[],
        'testStats': <String, dynamic>{},
      });

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
      await _authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (exception) {
      return exception.message;
    }
  }

  Future<void> logout() async {
    await _authInstance.signOut();
  }
}
