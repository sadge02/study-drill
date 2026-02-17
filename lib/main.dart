import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:study_drill/screens/error/initialization_error_screen.dart';
import 'package:study_drill/utils/constants/general_constants.dart';
import 'package:study_drill/widgets/wrapper/authentication/authentication_gate.dart';

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
  } catch (_) {
    runApp(const InitializationErrorScreen(onRestart: initializeApp));
  }
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
      home: AuthenticationGate(onRestart: onRestart),
    );
  }
}
