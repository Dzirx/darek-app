// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/models/meeting.dart';
import '../database/models/sale.dart';
import '../database/models/user.dart';
import '../database/models/client.dart';
import '../database/models/client_note.dart';

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
        reminderTimes TEXT,
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

        await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        company TEXT,
        address TEXT,
        phoneNumber TEXT,
        email TEXT,
        userId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        category TEXT NOT NULL,
        isActive INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

        await db.execute('''
      CREATE TABLE client_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientId INTEGER NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        userId INTEGER NOT NULL,
        type TEXT NOT NULL,
        importance TEXT NOT NULL,
        tags TEXT,
        FOREIGN KEY (clientId) REFERENCES clients (id),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('CREATE INDEX idx_client_notes_client_id ON client_notes(clientId)');
    await db.execute('CREATE INDEX idx_client_notes_created_at ON client_notes(createdAt)');
    await db.execute('CREATE INDEX idx_clients_name ON clients(name)');
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

    Future<int> createClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> searchClients(String query, int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'userId = ? AND (name LIKE ? OR company LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<List<Client>> getRecentClients(int userId, {int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT c.*
      FROM clients c
      LEFT JOIN client_notes n ON c.id = n.clientId
      WHERE c.userId = ?
      GROUP BY c.id
      ORDER BY MAX(COALESCE(n.createdAt, c.updatedAt)) DESC
      LIMIT ?
    ''', [userId, limit]);
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  // Metody dla notatek
  Future<int> createNote(ClientNote note) async {
    final db = await database;
    return await db.insert('client_notes', note.toMap());
  }

  Future<List<ClientNote>> getNotesForClient(int clientId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'client_notes',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => ClientNote.fromMap(map)).toList();
  }

  Future<List<ClientNote>> searchNotes(String query, int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT n.*
      FROM client_notes n
      JOIN clients c ON n.clientId = c.id
      WHERE n.userId = ? AND (
        n.content LIKE ? OR
        n.tags LIKE ? OR
        c.name LIKE ?
      )
      ORDER BY n.createdAt DESC
    ''', [userId, '%$query%', '%$query%', '%$query%']);
    return maps.map((map) => ClientNote.fromMap(map)).toList();
  }

  Future<List<String>> getAllTags(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'client_notes',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    
    final Set<String> tags = {};
    for (var map in maps) {
      final note = ClientNote.fromMap(map);
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  Future<List<ClientNote>> getRecentNotes(int userId, {int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'client_notes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map((map) => ClientNote.fromMap(map)).toList();
  }

  Future<List<ClientNote>> getNotesByType(int clientId, NoteType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'client_notes',
      where: 'clientId = ? AND type = ?',
      whereArgs: [clientId, type.toString()],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => ClientNote.fromMap(map)).toList();
  }
}

