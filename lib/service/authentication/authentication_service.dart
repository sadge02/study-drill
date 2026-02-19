import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:study_drill/models/user/user_model.dart';
import 'package:study_drill/utils/constants/collections/database_constants.dart';
import 'package:study_drill/utils/constants/validator/authentication_validator_constants.dart';
import 'package:study_drill/utils/validators/authentication_validator.dart';

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
        return AuthenticationValidatorConstants.usernameTakenMessage;
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
      return AuthenticationValidatorConstants.unexpectedErrorMessage;
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
      case AuthenticationValidatorConstants.weakPasswordException:
        return AuthenticationValidatorConstants.passwordWeakMessage;
      case AuthenticationValidatorConstants.emailAlreadyInUseException:
        return AuthenticationValidatorConstants.emailAlreadyInUseMessage;
      case AuthenticationValidatorConstants.userNotFoundException:
        return AuthenticationValidatorConstants.userNotFoundMessage;
      case AuthenticationValidatorConstants.wrongPasswordException:
        return AuthenticationValidatorConstants.passwordWrongMessage;
      case AuthenticationValidatorConstants.invalidCredentialException:
        return AuthenticationValidatorConstants.invalidCredentialsMessage;
      case AuthenticationValidatorConstants.invalidEmailException:
        return AuthenticationValidatorConstants.emailInvalidMessage;
      case AuthenticationValidatorConstants.userDisabledException:
        return AuthenticationValidatorConstants.userDisabledMessage;
      case AuthenticationValidatorConstants.tooManyRequestsException:
        return AuthenticationValidatorConstants.tooManyRequestsMessage;
      case AuthenticationValidatorConstants.networkRequestFailedException:
        return AuthenticationValidatorConstants.networkRequestFailed;
      default:
        return exception.message ??
            AuthenticationValidatorConstants.unexpectedErrorMessage;
    }
  }
}
