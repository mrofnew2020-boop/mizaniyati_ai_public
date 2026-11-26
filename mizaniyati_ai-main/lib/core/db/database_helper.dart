import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../utils/date_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'mizaniyati_ai.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        image_path TEXT,
        role TEXT NOT NULL DEFAULT 'manager'
      )
    ''');

    await db.execute('''
      CREATE TABLE income_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        default_amount REAL,
        pay_day INTEGER,
        is_archived INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE income_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_id INTEGER,
        source_name_snapshot TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (source_id) REFERENCES income_sources(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_income_date ON income_entries(date)');

    await db.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT,
        cap REAL,
        cap_mode TEXT DEFAULT 'manual',
        is_archived INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        category_name_snapshot TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        uuid TEXT NOT NULL UNIQUE,
        member_name TEXT,
        created_at TEXT NOT NULL,
        modified_at TEXT,
        FOREIGN KEY (category_id) REFERENCES expense_categories(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_expense_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expense_category ON expenses(category_id)');
    await db.execute('CREATE INDEX idx_expense_uuid ON expenses(uuid)');

    await db.execute('''
      CREATE TABLE import_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_member TEXT,
        imported_count INTEGER DEFAULT 0,
        skipped_count INTEGER DEFAULT 0,
        imported_at TEXT NOT NULL
      )
    ''');

    final now = DateTime.now().toIso8601String();
    for (int i = 0; i < AppConstants.defaultCategories.length; i++) {
      final cat = AppConstants.defaultCategories[i];
      await db.insert('expense_categories', {
        'name': cat['name'],
        'type': cat['type'],
        'icon': cat['icon'],
        'cap': null,
        'cap_mode': 'manual',
        'is_archived': 0,
        'sort_order': i,
        'created_at': now,
      });
    }
  }

  // ===== دوال إضافية للميزانية اليومية =====
  Future<DateTime?> getFirstFixedIncomeDate() async {
    final db = await database;
    final r = await db.rawQuery('''
      SELECT MIN(date) AS first_date 
      FROM income_entries 
      JOIN income_sources ON income_entries.source_id = income_sources.id 
      WHERE income_sources.type = 'ثابت'
    ''');
    if (r.isNotEmpty && r.first['first_date'] != null) {
      return DateTime.parse(r.first['first_date'] as String);
    }
    return null;
  }

  // ===== دوال الاستعلام الحسابية السابقة =====
  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM income_entries WHERE date >= ? AND date <= ?',
      [DateHelper.toDbDate(start), DateHelper.toDbDate(end)],
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalExpense(DateTime start, DateTime end) async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses WHERE date >= ? AND date <= ?',
      [DateHelper.toDbDate(start), DateHelper.toDbDate(end)],
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getCategoryTotal(
      int categoryId, DateTime start, DateTime end) async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses '
      'WHERE category_id = ? AND date >= ? AND date <= ?',
      [categoryId, DateHelper.toDbDate(start), DateHelper.toDbDate(end)],
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<Map<int, double>> getCategoryTotalsMap(
      DateTime start, DateTime end) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT category_id, SUM(amount) AS total FROM expenses '
      'WHERE date >= ? AND date <= ? AND category_id IS NOT NULL '
      'GROUP BY category_id',
      [DateHelper.toDbDate(start), DateHelper.toDbDate(end)],
    );
    final map = <int, double>{};
    for (final row in rows) {
      final cid = row['category_id'] as int?;
      if (cid != null) {
        map[cid] = (row['total'] as num?)?.toDouble() ?? 0;
      }
    }
    return map;
  }

  Future<double?> getCategoryAverage3Months(int categoryId, int payDay) async {
    final db = await database;
    double total = 0;
    int monthsWithData = 0;

    for (int i = 1; i <= AppConstants.spikeMonthsWindow; i++) {
      final (start, end) = DateHelper.periodOffset(payDay, -i);
      final r = await db.rawQuery(
        'SELECT COUNT(*) AS cnt, SUM(amount) AS total FROM expenses '
        'WHERE category_id = ? AND date >= ? AND date <= ?',
        [categoryId, DateHelper.toDbDate(start), DateHelper.toDbDate(end)],
      );
      final cnt = (r.first['cnt'] as int?) ?? 0;
      if (cnt > 0) {
        total += (r.first['total'] as num?)?.toDouble() ?? 0;
        monthsWithData++;
      }
    }

    if (monthsWithData == 0) return null;
    return total / monthsWithData;
  }

  Future<Map<int, double>> getCategoryTotalsForPeriods(
      int categoryId, int payDay, int periodsCount) async {
    final db = await database;
    final map = <int, double>{};

    for (int i = 0; i < periodsCount; i++) {
      final (start, end) = DateHelper.periodOffset(payDay, -i);
      final r = await db.rawQuery(
        'SELECT SUM(amount) AS total FROM expenses '
        'WHERE category_id = ? AND date >= ? AND date <= ?',
        [categoryId, DateHelper.toDbDate(start), DateHelper.toDbDate(end)],
      );
      map[i] = (r.first['total'] as num?)?.toDouble() ?? 0;
    }
    return map;
  }

  Future<bool> expenseUuidExists(String uuid) async {
    final db = await database;
    final r = await db.query('expenses',
        columns: ['id'], where: 'uuid = ?', whereArgs: [uuid], limit: 1);
    return r.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> findSuspectExpenses({
    required double amount,
    required String date,
    required String categoryName,
  }) async {
    final db = await database;
    return db.query(
      'expenses',
      columns: ['id', 'amount', 'date', 'category_name_snapshot', 'member_name'],
      where: 'amount = ? AND date = ? AND category_name_snapshot = ?',
      whereArgs: [amount, date, categoryName],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentExpenses({int limit = 10}) async {
    final db = await database;
    return db.query('expenses',
        orderBy: 'date DESC, created_at DESC', limit: limit);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await database;
    final r = await db.query('user_profile', where: 'id = 1', limit: 1);
    return r.isEmpty ? null : r.first;
  }

  Future<void> upsertProfile(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('user_profile', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
