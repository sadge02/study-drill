import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user/user_model.dart';
import '../../utils/constants/collections/database_constants.dart';
import '../../utils/constants/error/messages/firebase_exception_constants.dart';
import '../../utils/validators/authentication/authentication_validator.dart';

/// Handles Firebase Authentication and the creation/validation of user accounts.
class AuthenticationService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final FirebaseFirestore _database = FirebaseFirestore.instance;

  /// --------------------------------------------------------------------------
  /// Username availability
  /// --------------------------------------------------------------------------

  /// Returns true if [username] is already reserved in the usernames collection.
  Future<bool> isUsernameTaken(String username) async {
    final document = await _database
        .collection(DatabaseConstants.usernamesCollection)
        .doc(username.trim().toLowerCase())
        .get();
    return document.exists;
  }

  /// --------------------------------------------------------------------------
  /// Registration
  /// --------------------------------------------------------------------------

  /// Creates a new user account.
  Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    String? profilePicUrl,
  }) async {
    final validationError = _validateInputs(
      username.trim(),
      email.trim(),
      password,
    );

    if (validationError != null) {
      return validationError;
    }

    try {
      if (await isUsernameTaken(username.trim())) {
        return FirebaseExceptionConstants.usernameTakenMessage;
      }
    } catch (_) {}

    UserCredential? credentials;

    try {
      credentials = await _authentication.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credentials.user;

      if (user == null) {
        return FirebaseExceptionConstants.unexpectedErrorMessage;
      }

      final encodedUsername = Uri.encodeComponent(username.trim());

      final profilePic = (profilePicUrl?.trim().isNotEmpty == true)
          ? profilePicUrl!
          : 'https://ui-avatars.com/api/?name=$encodedUsername&background=27374D&color=fff';

      final now = DateTime.now();

      final newUser = UserModel(
        id: user.uid,
        email: email.trim(),
        username: username.trim(),
        description: '',
        profilePic: profilePic,
        createdAt: now,
        updatedAt: now,
      );

      await _database.runTransaction((transaction) async {
        final usernameDoc = await transaction.get(
          _database
              .collection(DatabaseConstants.usernamesCollection)
              .doc(username.trim().toLowerCase()),
        );

        if (usernameDoc.exists) {
          throw Exception(FirebaseExceptionConstants.usernameTakenMessage);
        }

        transaction.set(
          _database
              .collection(DatabaseConstants.usernamesCollection)
              .doc(username.trim().toLowerCase()),
          {'uid': user.uid},
        );

        transaction.set(
          _database.collection(DatabaseConstants.usersCollection).doc(user.uid),
          newUser.toJson(),
        );
      });

      try {
        await Future.wait([
          user.updateDisplayName(username.trim()),
          user.updatePhotoURL(profilePic),
        ]);
      } catch (_) {}
      return null;
    } on FirebaseAuthException catch (exception) {
      return _handleAuthError(exception);
    } catch (exception) {
      if (credentials?.user != null) {
        try {
          await credentials!.user!.delete();
        } catch (_) {}
      }

      if (exception is Exception &&
          exception.toString().contains(
            FirebaseExceptionConstants.usernameTakenMessage,
          )) {
        return FirebaseExceptionConstants.usernameTakenMessage;
      }
      return FirebaseExceptionConstants.unexpectedErrorMessage;
    }
  }

  /// --------------------------------------------------------------------------
  /// Login
  /// --------------------------------------------------------------------------

  /// Signs in an existing user with [email] and [password].
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _authentication.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (exception) {
      return _handleAuthError(exception);
    } catch (_) {
      return FirebaseExceptionConstants.unexpectedErrorMessage;
    }
  }

  /// --------------------------------------------------------------------------
  /// Password reset
  /// --------------------------------------------------------------------------

  /// Sends a password reset email to [email].
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _authentication.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (exception) {
      return _handleAuthError(exception);
    } catch (_) {
      return FirebaseExceptionConstants.unexpectedErrorMessage;
    }
  }

  /// --------------------------------------------------------------------------
  /// Logout
  /// --------------------------------------------------------------------------

  /// Signs out the current user.
  Future<void> logout() async {
    await _authentication.signOut();
  }

  /// --------------------------------------------------------------------------
  /// Helpers
  /// --------------------------------------------------------------------------

  /// Validates username, email, and password.
  String? _validateInputs(String username, String email, String password) {
    return AuthenticationValidator.validateUsername(username) ??
        AuthenticationValidator.validateEmail(email) ??
        AuthenticationValidator.validatePassword(password);
  }

  /// Maps a [FirebaseAuthException] error code to a user-facing error string.
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
