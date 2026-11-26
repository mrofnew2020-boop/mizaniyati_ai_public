import 'package:flutter/foundation.dart';
import '../models/expense_category.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final _service = CategoryService();
  List<ExpenseCategory> _categories = [];
  bool _loading = false;

  List<ExpenseCategory> get categories => _categories;
  List<ExpenseCategory> get fixed =>
      _categories.where((c) => c.isFixed).toList();
  List<ExpenseCategory> get variable =>
      _categories.where((c) => !c.isFixed).toList();
  bool get loading => _loading;

  ExpenseCategory? byId(int? id) {
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _categories = await _service.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<int> addCategory({
    required String name,
    required String type,
    required String icon,
    String? color,
    double? cap,
    String capMode = 'manual',
  }) async {
    final id = await _service.addCategory(
      name: name, type: type, icon: icon, color: color, cap: cap, capMode: capMode);
    if (id > 0) await load();
    return id;
  }

  Future<bool> updateCategory(ExpenseCategory cat) async {
    final ok = await _service.updateCategory(cat);
    if (ok) await load();
    return ok;
  }

  Future<void> archiveCategory(int id) async {
    await _service.archiveCategory(id);
    await load();
  }

  Future<void> restoreCategory(int id) async {
    await _service.restoreCategory(id);
    await load();
  }

  Future<void> deleteWithTransfer({
    required int categoryId,
    required int? targetCategoryId,
  }) async {
    await _service.deleteWithTransfer(
      categoryId: categoryId, targetCategoryId: targetCategoryId);
    await load();
  }

  Future<int> countExpenses(int categoryId) => _service.countExpenses(categoryId);
}
