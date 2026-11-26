import '../core/db/database_helper.dart';
import '../models/expense_category.dart';

class CategoryService {
  final _db = DatabaseHelper.instance;

  Future<List<ExpenseCategory>> getAll({bool includeArchived = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'expense_categories',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(ExpenseCategory.fromMap).toList();
  }

  Future<ExpenseCategory?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query('expense_categories',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : ExpenseCategory.fromMap(rows.first);
  }

  Future<ExpenseCategory?> getByName(String name) async {
    final db = await _db.database;
    final rows = await db.query('expense_categories',
        where: 'name = ?', whereArgs: [name], limit: 1);
    return rows.isEmpty ? null : ExpenseCategory.fromMap(rows.first);
  }

  Future<int> addCategory({
    required String name,
    required String type,
    required String icon,
    String? color,
    double? cap,
    String capMode = 'manual',
  }) async {
    final db = await _db.database;
    if (await getByName(name) != null) return -1;
    final now = DateTime.now().toIso8601String();
    return db.insert('expense_categories', {
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'cap': cap,
      'cap_mode': capMode,
      'is_archived': 0,
      'sort_order': 999,
      'created_at': now,
    });
  }

  Future<bool> updateCategory(ExpenseCategory category) async {
    final db = await _db.database;
    final existing = await getByName(category.name);
    if (existing != null && existing.id != category.id) return false;
    await db.update('expense_categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
    return true;
  }

  Future<void> archiveCategory(int id) async {
    final db = await _db.database;
    await db.update('expense_categories', {'is_archived': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> restoreCategory(int id) async {
    final db = await _db.database;
    await db.update('expense_categories', {'is_archived': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countExpenses(int categoryId) async {
    final db = await _db.database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM expenses WHERE category_id = ?',
        [categoryId]);
    return (r.first['c'] as int?) ?? 0;
  }

  Future<void> deleteWithTransfer({
    required int categoryId,
    required int? targetCategoryId,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      if (targetCategoryId != null) {
        final targetRows = await txn.query('expense_categories',
            columns: ['name'],
            where: 'id = ?',
            whereArgs: [targetCategoryId],
            limit: 1);
        if (targetRows.isNotEmpty) {
          final targetName = targetRows.first['name'] as String;
          await txn.update(
            'expenses',
            {
              'category_id': targetCategoryId,
              'category_name_snapshot': targetName,
              'modified_at': DateTime.now().toIso8601String(),
            },
            where: 'category_id = ?',
            whereArgs: [categoryId],
          );
        }
      }
      await txn.delete('expense_categories',
          where: 'id = ?', whereArgs: [categoryId]);
    });
  }
}
