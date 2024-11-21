// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../database/models/user.dart';
import '../widgets/speech_recognition_widget.dart';
import '../screens/calendar_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  
  const HomeScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Witaj, ${user.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildMenuCard(
                  context: context,
                  icon: Icons.calendar_month,
                  title: 'Kalendarz',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalendarScreen(userId: user.id!),
                      ),
                    );
                  },
                ),
                // Add more menu cards here
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SpeechRecognitionWidget(
                userId: user.id!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 150,
          height: 150,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}