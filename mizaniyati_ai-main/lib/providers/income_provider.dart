import 'package:flutter/foundation.dart';
import '../core/db/database_helper.dart';
import '../core/utils/date_helper.dart';
import '../models/income_entry.dart';
import '../models/income_source.dart';
import '../services/income_service.dart';

class IncomeProvider extends ChangeNotifier {
  final _service = IncomeService();
  final _db = DatabaseHelper.instance;
  List<IncomeSource> _sources = [];
  List<IncomeEntry> _periodEntries = [];
  double _periodTotal = 0;
  bool _loading = false;
  int _payDay = 1;

  List<IncomeSource> get sources => _sources;
  List<IncomeEntry> get periodEntries => _periodEntries;
  double get periodTotal => _periodTotal;
  bool get loading => _loading;

  Future<void> load(int payDay) async {
    _loading = true;
    _payDay = payDay;
    notifyListeners();
    _sources = await _service.getAllSources();
    final (start, end) = DateHelper.currentPeriod(payDay);
    _periodTotal = await _db.getTotalIncome(start, end);
    _periodEntries = await _service.getEntriesBetween(start, end);
    _loading = false;
    notifyListeners();
  }

  Future<int> addSource(IncomeSource s) async {
    final id = await _service.addSource(s);
    await load(_payDay);
    return id;
  }

  Future<void> updateSource(IncomeSource s) async {
    await _service.updateSource(s);
    await load(_payDay);
  }

  Future<void> archiveSource(int id) async {
    await _service.archiveSource(id);
    await load(_payDay);
  }

  Future<int> addEntry(IncomeEntry e) async {
    final id = await _service.addEntry(e);
    await load(_payDay);
    return id;
  }

  Future<void> deleteEntry(int id) async {
    await _service.deleteEntry(id);
    await load(_payDay);
  }
}
