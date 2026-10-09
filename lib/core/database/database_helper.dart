import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/expense_item.dart';

class DatabaseHelper {
  static const String _dbName = 'expenses.db';
  static const int _dbVersion = 1;
  static const String tableName = 'expenses';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        merchantName TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        rawOcrText TEXT,
        imagePath TEXT
      )
    ''');
  }

  // CRUD Operations

  Future<int> insertExpense(ExpenseItem expense) async {
    final db = await database;
    return await db.insert(
      tableName,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => ExpenseItem.fromMap(map)).toList();
  }

  Future<ExpenseItem?> getExpenseById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ExpenseItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(ExpenseItem expense) async {
    final db = await database;
    return await db.update(
      tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllExpenses() async {
    final db = await database;
    return await db.delete(tableName);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
