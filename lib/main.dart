import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:study_drill/screens/authentication/authentication_login_screen.dart';
import 'package:study_drill/screens/home/home_screen.dart';
import 'package:study_drill/utils/constants/core/general_constants.dart';

import 'config/firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeApp();
}

Future<void> initializeApp() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const StudyDrillApp(onRestart: initializeApp));
  } catch (_) {}
}

class StudyDrillApp extends StatelessWidget {
  const StudyDrillApp({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GeneralConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: GeneralConstants.primaryColor,
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const AuthenticationLoginScreen();
        },
      ),
    );
  }
}
