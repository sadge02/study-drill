import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_drill/screens/error/initialization_error_screen.dart';

import '../../../screens/authentication/login_screen.dart';
import '../../../screens/navigation/home_screen.dart';

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return InitializationErrorScreen(onRestart: onRestart);
        }
        if (snapshot.hasData) {
          return HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
