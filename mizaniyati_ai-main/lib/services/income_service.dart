import '../core/db/database_helper.dart';
import '../models/income_entry.dart';
import '../models/income_source.dart';

class IncomeService {
  final _db = DatabaseHelper.instance;

  Future<List<IncomeSource>> getAllSources({bool includeArchived = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      'income_sources',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'type ASC, name ASC',
    );
    return rows.map(IncomeSource.fromMap).toList();
  }

  Future<int> addSource(IncomeSource source) async {
    final db = await _db.database;
    return db.insert('income_sources', source.toMap());
  }

  Future<void> updateSource(IncomeSource source) async {
    final db = await _db.database;
    await db.update('income_sources', source.toMap(),
        where: 'id = ?', whereArgs: [source.id]);
  }

  Future<void> archiveSource(int id) async {
    final db = await _db.database;
    await db.update('income_sources', {'is_archived': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> restoreSource(int id) async {
    final db = await _db.database;
    await db.update('income_sources', {'is_archived': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<IncomeEntry>> getEntriesBetween(
      DateTime start, DateTime end) async {
    final db = await _db.database;
    final rows = await db.query(
      'income_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [_date(start), _date(end)],
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(IncomeEntry.fromMap).toList();
  }

  Future<int> addEntry(IncomeEntry entry) async {
    final db = await _db.database;
    return db.insert('income_entries', entry.toMap());
  }

  Future<void> updateEntry(IncomeEntry entry) async {
    final db = await _db.database;
    await db.update('income_entries', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deleteEntry(int id) async {
    final db = await _db.database;
    await db.delete('income_entries', where: 'id = ?', whereArgs: [id]);
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
