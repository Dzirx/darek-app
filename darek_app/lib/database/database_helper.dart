// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/models/meeting.dart';
import '../database/models/sale.dart';
import '../database/models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabela użytkowników
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    // Tabela spotkań
    await db.execute('''
      CREATE TABLE meetings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dateTime TEXT NOT NULL,
        hasReminder INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Tabela sprzedaży
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        clientName TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        description TEXT,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }

  // Metody dla spotkań
  Future<int> createMeeting(Meeting meeting) async {
    final db = await database;
    return await db.insert('meetings', meeting.toMap());
  }

  Future<Meeting?> getMeeting(int id) async {
    final db = await database;
    final maps = await db.query(
      'meetings',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Meeting.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Meeting>> getMeetingsForDay(DateTime date, int userId) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      'meetings',
      where: 'userId = ? AND dateTime BETWEEN ? AND ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'dateTime ASC',
    );

    return maps.map((map) => Meeting.fromMap(map)).toList();
  }

  Future<List<Meeting>> getMeetingsForMonth(int userId, int year, int month) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    final maps = await db.query(
      'meetings',
      where: 'userId = ? AND dateTime BETWEEN ? AND ?',
      whereArgs: [userId, startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      orderBy: 'dateTime ASC',
    );

    return maps.map((map) => Meeting.fromMap(map)).toList();
  }

  Future<int> updateMeeting(Meeting meeting) async {
    final db = await database;
    return await db.update(
      'meetings',
      meeting.toMap(),
      where: 'id = ?',
      whereArgs: [meeting.id],
    );
  }

  Future<int> deleteMeeting(int id) async {
    final db = await database;
    return await db.delete(
      'meetings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Metody dla sprzedaży
  Future<int> createSale(Sale sale) async {
    final db = await database;
    return await db.insert('sales', sale.toMap());
  }

  Future<List<Sale>> getSalesForUser(int userId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (startDate != null && endDate != null) {
      whereClause += ' AND dateTime BETWEEN ? AND ?';
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    final maps = await db.query(
      'sales',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'dateTime DESC',
    );

    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  Future<double> getTotalSalesForPeriod(int userId, DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM sales
      WHERE userId = ? AND dateTime BETWEEN ? AND ?
    ''', [userId, startDate.toIso8601String(), endDate.toIso8601String()]);

    return result.first['total'] as double? ?? 0.0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
   Future<List<Meeting>> getMeetingsForPeriod(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).toIso8601String();
    
    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    ).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'meetings',
      where: 'userId = ? AND dateTime BETWEEN ? AND ?',
      whereArgs: [userId, normalizedStartDate, normalizedEndDate],
      orderBy: 'dateTime ASC',
    );

    return maps.map((map) => Meeting.fromMap(map)).toList();
  }
}
