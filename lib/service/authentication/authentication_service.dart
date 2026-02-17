import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:study_drill/models/user/user_model.dart';
import 'package:study_drill/utils/constants/validator/authentication_validator_constants.dart';
import 'package:study_drill/utils/validators/authentication_validator.dart';

class AuthenticationService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;

  final FirebaseFirestore _database = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const String _userCollection = 'users';
  static const String _usernameCollection = 'usernames';

  Future<bool> isUsernameTaken(String username) async {
    final doc = await _database
        .collection(_usernameCollection)
        .doc(username.toLowerCase())
        .get();
    return doc.exists;
  }

  Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    String? profilePicUrl,
  }) async {
    try {
      final error = _validateInputs(username, email, password);
      if (error != null) {
        return error;
      }

      if (await isUsernameTaken(username)) {
        return AuthenticationValidatorConstants.usernameTakenMessage;
      }

      final credentials = await _authentication.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final String uid = credentials.user!.uid;

      final String profilePic =
          profilePicUrl ??
          'https://ui-avatars.com/api/?name=$username&background=27374D&color=fff';

      String? token;
      try {
        token = await _messaging.getToken();
      } catch (_) {}

      final UserModel newUser = UserModel(
        id: uid,
        email: email.trim(),
        username: username.trim(),
        usernameLowercase: username.trim().toLowerCase(),
        summary: '',
        profilePic: profilePic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fcmToken: token,
        groupIds: [],
      );

      final WriteBatch batch = _database.batch();

      batch.set(
        _database.collection(_userCollection).doc(uid),
        newUser.toJson(),
      );

      batch.set(
        _database
            .collection(_usernameCollection)
            .doc(username.trim().toLowerCase()),
        {'uid': uid},
      );

      await batch.commit();

      await credentials.user?.updateDisplayName(username);
      await credentials.user?.updatePhotoURL(profilePic);

      return null;
    } on FirebaseAuthException catch (exception) {
      return _handleAuthError(exception);
    } catch (_) {
      return AuthenticationValidatorConstants.unexpectedErrorMessage;
    }
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await _authentication.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      _updateDeviceToken(credentials.user!.uid);

      return null;
    } on FirebaseAuthException catch (exception) {
      return _handleAuthError(exception);
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _authentication.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (exception) {
      return _handleAuthError(exception);
    }
  }

  Future<void> logout() async {
    await _authentication.signOut();
  }

  String? _validateInputs(String username, String email, String password) {
    final usernameError = AuthenticationValidator.validateUsername(username);
    if (usernameError != null) {
      return usernameError;
    }

    final emailError = AuthenticationValidator.validateEmail(email);
    if (emailError != null) {
      return emailError;
    }

    final passwordError = AuthenticationValidator.validatePassword(password);
    if (passwordError != null) {
      return passwordError;
    }

    return null;
  }

  String _handleAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'weak-password':
        return AuthenticationValidatorConstants.weakPasswordMessage;
      case 'email-already-in-use':
        return AuthenticationValidatorConstants.emailAlreadyInUseMessage;
      case 'user-not-found':
        return AuthenticationValidatorConstants.userNotFoundMessage;
      case 'wrong-password':
        return AuthenticationValidatorConstants.wrongPasswordMessage;
      case 'invalid-email':
        return AuthenticationValidatorConstants.emailNotValidMessage;
      default:
        return exception.message ??
            AuthenticationValidatorConstants.authenticationFailedMessage;
    }
  }

  Future<void> _updateDeviceToken(String uid) async {
    try {
      final String? token = await _messaging.getToken();
      if (token != null) {
        await _database.collection(_userCollection).doc(uid).update({
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }
}
