import 'package:flutter/foundation.dart';
import '../core/db/database_helper.dart';
import '../core/utils/date_helper.dart';
import '../models/expense.dart';
import '../services/category_service.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final _service = ExpenseService();
  final _db = DatabaseHelper.instance;
  List<Expense> _recentExpenses = [];
  List<Expense> _periodExpenses = [];
  double _periodTotal = 0;
  Map<int, double> _categoryTotals = {};
  Map<int, CapStatus> _capStatuses = {};
  bool _loading = false;
  int _payDay = 1;

  List<Expense> get recentExpenses => _recentExpenses;
  List<Expense> get periodExpenses => _periodExpenses;
  double get periodTotal => _periodTotal;
  Map<int, double> get categoryTotals => _categoryTotals;
  Map<int, CapStatus> get capStatuses => _capStatuses;
  bool get loading => _loading;

  Future<void> load(int payDay) async {
    _loading = true;
    _payDay = payDay;
    notifyListeners();
    final (start, end) = DateHelper.currentPeriod(payDay);
    _periodTotal = await _db.getTotalExpense(start, end);
    _categoryTotals = await _db.getCategoryTotalsMap(start, end);
    _periodExpenses = await _service.getExpensesBetween(start, end);
    final recentRows = await _db.getRecentExpenses(limit: 10);
    _recentExpenses = recentRows.map(Expense.fromMap).toList();
    _capStatuses = {};
    final cats = await CategoryService().getAll();
    for (final c in cats) {
      if (c.hasCap && c.id != null) {
        final total = _categoryTotals[c.id!] ?? 0;
        _capStatuses[c.id!] = CapStatus(
          exceeded: total > c.cap!, cap: c.cap!,
          currentTotal: total, ratio: c.cap! > 0 ? total / c.cap! : 0);
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<CapStatus?> addExpense({
    required int categoryId,
    required String categoryName,
    required double amount,
    required DateTime date,
    String? note,
    String? memberName,
  }) async {
    await _service.addExpense(
      categoryId: categoryId, categoryName: categoryName,
      amount: amount, date: date, note: note, memberName: memberName);
    await load(_payDay);
    return _capStatuses[categoryId];
  }

  Future<void> deleteExpense(int id) async {
    await _service.deleteExpense(id);
    await load(_payDay);
  }

  Future<void> updateExpense(Expense e) async {
    await _service.updateExpense(e);
    await load(_payDay);
  }
}
