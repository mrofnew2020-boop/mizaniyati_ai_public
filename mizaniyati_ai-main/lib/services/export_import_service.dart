import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/db/database_helper.dart';
import '../core/utils/date_helper.dart';
import '../models/expense.dart';

enum ImportStatus { fresh, duplicate, suspect }

class ImportCandidate {
  final Map<String, dynamic> json;
  final ImportStatus status;
  final String? matchedNote;
  ImportCandidate({required this.json, required this.status, this.matchedNote});
  String get uuid => json['uuid'] as String;
  double get amount => (json['amount'] as num).toDouble();
  String get category => json['category'] as String? ?? 'أخرى';
  String get date => json['date'] as String;
  String? get note => json['note'] as String?;
}

class ImportPreview {
  final String memberName;
  final List<ImportCandidate> candidates;
  final DateTime exportedAt;
  ImportPreview({required this.memberName, required this.candidates, required this.exportedAt});
  int get freshCount => candidates.where((c) => c.status == ImportStatus.fresh).length;
  int get duplicateCount => candidates.where((c) => c.status == ImportStatus.duplicate).length;
  int get suspectCount => candidates.where((c) => c.status == ImportStatus.suspect).length;
}

class ExportImportService {
  final _db = DatabaseHelper.instance;

  Future<File> exportPeriod({
    required String memberName,
    required DateTime start,
    required DateTime end,
    required String? roleHint,
  }) async {
    final db = await _db.database;
    final rows = await db.query('expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [DateHelper.toDbDate(start), DateHelper.toDbDate(end)],
      orderBy: 'date ASC');
    final expenses = rows.map(Expense.fromMap).toList();
    final payload = {
      'app': 'MizaniyatiAI', 'version': 1,
      'memberName': memberName, 'role': roleHint,
      'exportedAt': DateTime.now().toIso8601String(),
      'periodStart': DateHelper.toDbDate(start),
      'periodEnd': DateHelper.toDbDate(end),
      'expenses': expenses.map((e) => e.toExportJson()).toList(),
    };
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/mizaniyati_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file;
  }

  Future<ImportPreview?> previewImport(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['app'] != 'MizaniyatiAI') return null;
      final memberName = (map['memberName'] as String?) ?? 'عضو';
      final exportedAt = DateTime.tryParse(map['exportedAt'] as String? ?? '') ?? DateTime.now();
      final list = (map['expenses'] as List<dynamic>? ?? []);
      final candidates = <ImportCandidate>[];
      for (final item in list) {
        final j = item as Map<String, dynamic>;
        final uuid = j['uuid'] as String?;
        if (uuid == null || uuid.isEmpty) continue;
        final exists = await _db.expenseUuidExists(uuid);
        if (exists) {
          candidates.add(ImportCandidate(json: j, status: ImportStatus.duplicate));
          continue;
        }
        final suspects = await _db.findSuspectExpenses(
          amount: (j['amount'] as num).toDouble(),
          date: j['date'] as String,
          categoryName: (j['category'] as String?) ?? 'أخرى');
        if (suspects.isNotEmpty) {
          candidates.add(ImportCandidate(json: j, status: ImportStatus.suspect,
            matchedNote: 'مطابق لمصروف من (${suspects.first['member_name'] ?? 'غير معروف'})'));
        } else {
          candidates.add(ImportCandidate(json: j, status: ImportStatus.fresh));
        }
      }
      return ImportPreview(memberName: memberName, candidates: candidates, exportedAt: exportedAt);
    } catch (_) {
      return null;
    }
  }

  Future<ImportResult> commitImport({
    required ImportPreview preview,
    required Set<String> selectedUuids,
    required Future<int?> Function(String) resolveCategoryId,
  }) async {
    final db = await _db.database;
    int imported = 0;
    int skipped = 0;
    for (final c in preview.candidates) {
      if (c.status == ImportStatus.duplicate || !selectedUuids.contains(c.uuid)) {
        skipped++;
        continue;
      }
      final catId = await resolveCategoryId(c.category);
      if (catId == null) {
        skipped++;
        continue;
      }
      final catRows = await db.query('expense_categories',
        columns: ['name'], where: 'id = ?', whereArgs: [catId], limit: 1);
      final resolvedName = catRows.isEmpty ? c.category : catRows.first['name'] as String;
      await db.insert('expenses', {
        'category_id': catId,
        'category_name_snapshot': resolvedName,
        'amount': c.amount, 'date': c.date, 'note': c.note,
        'uuid': c.uuid, 'member_name': preview.memberName,
        'created_at': c.json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        'modified_at': c.json['modifiedAt'],
      });
      imported++;
    }
    await db.insert('import_log', {
      'source_member': preview.memberName,
      'imported_count': imported, 'skipped_count': skipped,
      'imported_at': DateTime.now().toIso8601String(),
    });
    return ImportResult(imported: imported, skipped: skipped);
  }
}

class ImportResult {
  final int imported;
  final int skipped;
  const ImportResult({required this.imported, required this.skipped});
}
