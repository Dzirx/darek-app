// lib/services/auth_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/models/user.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  static Database? _database;
  User? _currentUser;

  User? get currentUser => _currentUser;

  AuthService._init();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'auth.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');
    
    await _createDefaultAdmin(db);
  }

  Future<void> _createDefaultAdmin(Database db) async {
    final defaultAdmin = {
      'username': 'admin',
      'password': _hashPassword('admin123'),
      'role': 'admin',
    };
    
    try {
      await db.insert('users', defaultAdmin);
      print('Utworzono domyślne konto administratora');
    } catch (e) {
      print('Błąd podczas tworzenia domyślnego konta: $e');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'twoj_tajny_klucz');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> authenticate(String username, String password) async {
    try {
      final db = await database;
      final hashedPassword = _hashPassword(password);
      
      final List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, hashedPassword],
      );

      if (results.isNotEmpty) {
        _currentUser = User.fromMap(results.first);
        return _currentUser;
      }
    } catch (e) {
      print('Błąd podczas logowania: $e');
    }
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
  }
}