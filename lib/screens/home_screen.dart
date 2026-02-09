import 'package:flutter/material.dart';

import '../authentication/service/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyDrill App Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().logout();
            },
          ),
        ],
      ),
      body: const Center(child: Text('Welcome! You are logged in.')),
    );
  }
}
