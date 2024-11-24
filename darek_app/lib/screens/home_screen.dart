import 'package:flutter/material.dart';
import '../database/models/user.dart';
import '../widgets/speech_recognition_widget.dart';
import '../screens/calendar_screen.dart';
import '../screens/client_notes_screen.dart';  
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../screens/sales_screen.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Karty menu w scrollowanym kontenerze
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMenuCard(
                      context: context,
                      icon: Icons.calendar_month,
                      title: 'Kalendarz',
                      subtitle: 'Spotkania i terminy',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CalendarScreen(userId: user.id!),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildMenuCard(
                      context: context,
                      icon: Icons.note_alt,
                      title: 'Notatki',
                      subtitle: 'Informacje o klientach',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientNotesScreen(userId: user.id!),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildMenuCard(
                      context: context,
                      icon: Icons.monetization_on,
                      title: 'Sprzedaż',
                      subtitle: 'Historia sprzedaży',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalesScreen(userId: user.id!),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Widget rozpoznawania mowy w pozostałej przestrzeni
              Expanded(
                child: SingleChildScrollView(
                  child: SpeechRecognitionWidget(
                    userId: user.id!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 140, // Zmniejszona szerokość
          height: 140, // Zmniejszona wysokość
          padding: const EdgeInsets.all(12), // Zmniejszony padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Zmniejszony padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 36, // Zmniejszona ikona
                  color: color,
                ),
              ),
              const SizedBox(height: 8), // Zmniejszony spacing
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14, // Zmniejszona czcionka
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11, // Zmniejszona czcionka
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}