import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../models/expense.dart';
import '../../providers/app_state.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/export_import_service.dart';

class RecorderHomeScreen extends StatefulWidget {
  const RecorderHomeScreen({super.key});
  @override
  State<RecorderHomeScreen> createState() => _RecorderHomeScreenState();
}

class _RecorderHomeScreenState extends State<RecorderHomeScreen> {
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final appState = context.read<AppState>();
    await Future.wait([
      context.read<CategoryProvider>().load(),
      context.read<ExpenseProvider>().load(appState.payDay),
    ]);
    if (mounted) setState(() => _initialLoad = false);
  }

  Future<void> _exportMyExpenses() async {
    final appState = context.read<AppState>();
    final (start, end) = DateHelper.currentPeriod(appState.payDay);
    final file = await ExportImportService().exportPeriod(
      memberName: appState.userName,
      start: start,
      end: end,
      roleHint: appState.role,
    );
    if (mounted) {
      await Share.shareXFiles([XFile(file.path)], subject: 'تصدير مصروفاتي');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final expense = context.watch<ExpenseProvider>();
    final todayExpenses = expense.recentExpenses.where((e) => e.date == DateHelper.toDbDate(DateTime.now())).toList();
    final todayTotal = todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مسجّل المصروفات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primaryBlue),
            onPressed: _exportMyExpenses,
            tooltip: 'إرسال مصروفاتي للمدير',
          ),
        ],
      ),
      body: _initialLoad
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقة مصروفات اليوم
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.cardElevated, AppColors.card],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPink.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('إجمالي مصروفات اليوم',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            CurrencyFormatter.formatShort(todayTotal),
                            style: const TextStyle(
                              color: AppColors.primaryPink,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('مصروفات اليوم',
                      style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    if (todayExpenses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('لم تسجل أي مصروف اليوم',
                            style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ...todayExpenses.map((e) => _expenseTile(e)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAdd(context),
        backgroundColor: AppColors.primaryPink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('مصروف جديد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _expenseTile(Expense e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.categoryNameSnapshot,
                  style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 14, fontWeight: FontWeight.w600)),
                if (e.note != null && e.note!.isNotEmpty)
                  Text(e.note!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(CurrencyFormatter.formatShort(e.amount),
            style: const TextStyle(color: AppColors.primaryPink,
              fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _showQuickAdd(BuildContext context) async {
    final cats = context.read<CategoryProvider>().categories;
    if (cats.isEmpty) return;
    int? selectedCatId = cats.first.id;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة مصروف',
                style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'المبلغ', prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedCatId,
                dropdownColor: AppColors.cardElevated,
                items: cats.map((c) => DropdownMenuItem(
                  value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setModal(() => selectedCatId = v),
                decoration: const InputDecoration(
                  hintText: 'التصنيف', prefixIcon: Icon(Icons.category_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'ملاحظات (اختياري)', prefixIcon: Icon(Icons.notes)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) return;
                    final cat = cats.firstWhere((c) => c.id == selectedCatId);
                    
                    await context.read<ExpenseProvider>().addExpense(
                      categoryId: cat.id!, 
                      categoryName: cat.name,
                      amount: amount, 
                      date: DateTime.now(),
                      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      memberName: context.read<AppState>().userName);
                      
                    if (!modalCtx.mounted) return;
                    Navigator.pop(modalCtx);
                    if (mounted) {
                      await _loadAll(); // تحديث القائمة بعد الإضافة
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
