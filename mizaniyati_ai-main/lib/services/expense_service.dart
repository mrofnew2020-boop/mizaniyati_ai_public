import '../core/db/database_helper.dart';
import '../core/utils/date_helper.dart';
import '../core/utils/uuid_gen.dart';
import '../models/expense.dart';

class ExpenseService {
  final _db = DatabaseHelper.instance;

  Future<int> addExpense({
    required int categoryId,
    required String categoryName,
    required double amount,
    required DateTime date,
    String? note,
    String? memberName,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    return db.insert('expenses', {
      'category_id': categoryId,
      'category_name_snapshot': categoryName,
      'amount': amount,
      'date': DateHelper.toDbDate(date),
      'note': note,
      'uuid': UuidGen.generate(),
      'member_name': memberName,
      'created_at': now,
      'modified_at': null,
    });
  }

  Future<void> updateExpense(Expense e) async {
    final db = await _db.database;
    final map = e.toMap();
    map['modified_at'] = DateTime.now().toIso8601String();
    await db.update('expenses', map, where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteExpense(int id) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpensesBetween(
      DateTime start, DateTime end, {int? categoryId, int limit = 200}) async {
    final db = await _db.database;
    final where = StringBuffer('date >= ? AND date <= ?');
    final args = <dynamic>[DateHelper.toDbDate(start), DateHelper.toDbDate(end)];
    if (categoryId != null) {
      where.write(' AND category_id = ?');
      args.add(categoryId);
    }
    final rows = await db.query(
      'expenses',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
    );
    return rows.map(Expense.fromMap).toList();
  }
}

class CapStatus {
  final bool exceeded;
  final double cap;
  final double currentTotal;
  final double ratio;

  const CapStatus({
    required this.exceeded,
    required this.cap,
    required this.currentTotal,
    required this.ratio,
  });
}
