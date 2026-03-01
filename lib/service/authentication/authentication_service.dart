import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:study_drill/models/user/user_model.dart';
import 'package:study_drill/utils/constants/collections/database_constants.dart';
import 'package:study_drill/utils/validators/authentication/authentication_validator.dart';

import '../../utils/constants/error/messages/firebase_exception_constants.dart';

class AuthenticationService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;

  final FirebaseFirestore _database = FirebaseFirestore.instance;

  static const String _userCollection = DatabaseConstants.usersCollection;
  static const String _usernameCollection =
      DatabaseConstants.usernamesCollection;

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
        return FirebaseExceptionConstants.usernameTakenMessage;
      }

      final credentials = await _authentication.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = credentials.user!.uid;

      final String profilePic =
          profilePicUrl ??
          'https://ui-avatars.com/api/?name=$username&background=27374D&color=fff';

      final UserModel newUser = UserModel(
        id: uid,
        email: email,
        username: username,
        usernameLowercase: username.toLowerCase(),
        summary: '',
        profilePic: profilePic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        groupIds: [],
      );

      final WriteBatch batch = _database.batch();

      batch.set(
        _database.collection(_userCollection).doc(uid),
        newUser.toJson(),
      );
      batch.set(
        _database.collection(_usernameCollection).doc(username.toLowerCase()),
        {'uid': uid},
      );

      await batch.commit();

      await credentials.user?.updateDisplayName(username);

      await credentials.user?.updatePhotoURL(profilePic);

      return null;
    } on FirebaseAuthException catch (exception) {
      return _handleAuthError(exception);
    } catch (_) {
      return FirebaseExceptionConstants.unexpectedErrorMessage;
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
      return _handleAuthError(exception);
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _authentication.sendPasswordResetEmail(email: email);

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
      case FirebaseExceptionConstants.weakPasswordException:
        return FirebaseExceptionConstants.passwordWeakMessage;
      case FirebaseExceptionConstants.emailAlreadyInUseException:
        return FirebaseExceptionConstants.emailAlreadyInUseMessage;
      case FirebaseExceptionConstants.userNotFoundException:
        return FirebaseExceptionConstants.userNotFoundMessage;
      case FirebaseExceptionConstants.wrongPasswordException:
        return FirebaseExceptionConstants.passwordWrongMessage;
      case FirebaseExceptionConstants.invalidCredentialException:
        return FirebaseExceptionConstants.invalidCredentialsMessage;
      case FirebaseExceptionConstants.invalidEmailException:
        return FirebaseExceptionConstants.emailInvalidMessage;
      case FirebaseExceptionConstants.userDisabledException:
        return FirebaseExceptionConstants.userDisabledMessage;
      case FirebaseExceptionConstants.tooManyRequestsException:
        return FirebaseExceptionConstants.tooManyRequestsMessage;
      case FirebaseExceptionConstants.networkRequestFailedException:
        return FirebaseExceptionConstants.networkRequestFailed;
      default:
        return exception.message ??
            FirebaseExceptionConstants.unexpectedErrorMessage;
    }
  }
}
