import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/expense_item.dart';
import '../constants/app_constants.dart';

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

    // Chèn sẵn các hóa đơn mẫu (Điện, Nước, Giải trí, Đồ ăn, Mua sắm, Di chuyển)
    for (final demo in getDemoExpenses()) {
      await db.insert(
        tableName,
        demo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Danh sách hóa đơn mẫu khởi tạo hiển thị ngay trên màn hình chính
  static List<ExpenseItem> getDemoExpenses() {
    final now = DateTime.now();
    return [
      ExpenseItem(
        id: 'demo-1',
        merchantName: 'Điện Lực Đà Nẵng (EVN CPC)',
        amount: 650000.0,
        category: AppConstants.categoryBills,
        timestamp: now.subtract(const Duration(hours: 3)),
        rawOcrText: 'TỔNG CÔNG TY ĐIỆN LỰC MIỀN TRUNG\nĐiện Lực Đà Nẵng\nHÓA ĐƠN TIỀN ĐIỆN SINH HOẠT\nTổng tiền thanh toán: 650.000 VNĐ',
      ),
      ExpenseItem(
        id: 'demo-2',
        merchantName: 'Nhà Hàng Cơm Niêu & Phở Hà Nội',
        amount: 320000.0,
        category: AppConstants.categoryFood,
        timestamp: now.subtract(const Duration(hours: 7)),
        rawOcrText: 'NHÀ HÀNG CƠM NIÊU ĐẶC SẢN\n1x Cơm niêu cá kho tộ\n1x Phở bò đặc biệt\n2x Trà đá\nTổng thanh toán: 320,000 đ',
      ),
      ExpenseItem(
        id: 'demo-3',
        merchantName: 'Rạp Phim CGV Vincom (Vé xem phim & Bắp nước)',
        amount: 240000.0,
        category: AppConstants.categoryEntertainment,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        rawOcrText: 'CGV CINEMAS VINCOM ĐÀ NẴNG\n2x Vé xem phim 2D + 1x Combo Bắp Nước\nTổng cộng: 240.000 VNĐ',
      ),
      ExpenseItem(
        id: 'demo-4',
        merchantName: 'Cấp Nước Dawaco (Hóa đơn tiền nước)',
        amount: 185000.0,
        category: AppConstants.categoryBills,
        timestamp: now.subtract(const Duration(days: 2, hours: 4)),
        rawOcrText: 'CÔNG TY CP CẤP NƯỚC ĐÀ NẴNG - DAWACO\nPhiếu thu tiền nước tháng 10\nKhách phải trả: 185.000 đ',
      ),
      ExpenseItem(
        id: 'demo-5',
        merchantName: 'Siêu Thị WinMart (Mua sắm thực phẩm)',
        amount: 275000.0,
        category: AppConstants.categoryShopping,
        timestamp: now.subtract(const Duration(days: 3, hours: 5)),
        rawOcrText: 'WINMART ĐÀ NẴNG\nSữa chua, Trái cây, Bánh mì, Nước ngọt\nTổng tiền: 275.000 đ',
      ),
      ExpenseItem(
        id: 'demo-6',
        merchantName: 'GrabCar (Chuyến đi Sân Bay Đà Nẵng)',
        amount: 135000.0,
        category: AppConstants.categoryTransport,
        timestamp: now.subtract(const Duration(days: 4, hours: 1)),
        rawOcrText: 'GRAB VIETNAM\nChuyến đi GrabCar 4 chỗ\nThanh toán: 135.000 VNĐ',
      ),
    ];
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

    if (maps.isEmpty) {
      // Nếu cơ sở dữ liệu trống, nạp sẵn dữ liệu mẫu
      for (final demo in getDemoExpenses()) {
        await db.insert(
          tableName,
          demo.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return getDemoExpenses();
    }

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
