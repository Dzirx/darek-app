// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Dodany import
import 'screens/login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ważne dla inicjalizacji bazy danych
  
  // Inicjalizacja lokalizacji dla formatowania dat
  await initializeDateFormatting('pl_PL', null);
  Intl.defaultLocale = 'pl_PL';
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Calendar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      locale: const Locale('pl', 'PL'), // Ustawienie lokalizacji aplikacji
      home: const LoginScreen(),
    );
  }
}