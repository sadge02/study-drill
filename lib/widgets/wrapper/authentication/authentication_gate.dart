import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_drill/screens/error/initialization_error_screen.dart';

import '../../../screens/authentication/login_screen.dart';
import '../../../screens/navigation/home_screen.dart';

/// Manages navigation flow based on Firebase authentication state.
///
/// This widget listens to FirebaseAuth's authentication state changes and
/// routes users to the appropriate screen:
/// - [HomeScreen] if authenticated
/// - [LoginScreen] if not authenticated
/// - Loading screen while checking authentication state
/// - Error screen if authentication check fails
class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state: Authentication state is being checked
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('AuthenticationGate: Checking authentication state...');
          return _buildLoadingScreen();
        }

        // Error state: Authentication stream encountered an error
        if (snapshot.hasError) {
          debugPrint('AuthenticationGate: Auth error - ${snapshot.error}');
          return InitializationErrorScreen(onRestart: onRestart);
        }

        // Authenticated: User is logged in
        if (snapshot.hasData) {
          debugPrint(
            'AuthenticationGate: User authenticated - ${snapshot.data?.email}',
          );
          return HomeScreen();
        }

        // Not authenticated: User not logged in
        debugPrint('AuthenticationGate: User not authenticated');
        return const LoginScreen();
      },
    );
  }

  /// Builds the loading screen shown while checking authentication state.
  Widget _buildLoadingScreen() {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
