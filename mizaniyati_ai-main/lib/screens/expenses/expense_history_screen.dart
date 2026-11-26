import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

class ExpenseHistoryScreen extends StatelessWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expProvider = context.watch<ExpenseProvider>();
    final expenses = expProvider.periodExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المصروفات'),
      ),
      body: expenses.isEmpty
          ? const Center(
              child: Text('لا توجد مصروفات مسجلة هذا الشهر',
                  style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return Dismissible(
                  key: Key('exp_${expense.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context),
                  onDismissed: (_) {
                    expProvider.deleteExpense(expense.id!);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => _showEditDialog(context, expense, expProvider),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.receipt_long,
                            color: AppColors.primaryPink, size: 22),
                      ),
                      title: Text(expense.categoryNameSnapshot,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عرض الملاحظة إذا وجدت
                          if (expense.note != null && expense.note!.isNotEmpty)
                            Text(expense.note!,
                                style: const TextStyle(
                                    color: AppColors.primaryBlue, fontSize: 12)),
                          Text(
                            DateHelper.formatArabic(DateTime.parse(expense.date)),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Text(
                        CurrencyFormatter.formatShort(expense.amount),
                        style: const TextStyle(
                            color: AppColors.primaryPink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        title: const Text('حذف المصروف',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('هل أنت متأكد من حذف هذا المصروف نهائياً؟',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, Expense expense, ExpenseProvider provider) async {
    final cats = context.read<CategoryProvider>().categories;
    int? selectedCatId = expense.categoryId ?? (cats.isNotEmpty ? cats.first.id : null);
    final amountCtrl =
        TextEditingController(text: expense.amount.toStringAsFixed(0));
    final noteCtrl = TextEditingController(text: expense.note ?? ''); // تعبئة الملاحظة الحالية
    DateTime date = DateTime.parse(expense.date);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تعديل المصروف',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              // خانة الملاحظات
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    hintText: 'ملاحظات (اختياري)', prefixIcon: Icon(Icons.notes)),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: modalCtx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setModal(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(DateHelper.formatArabic(date),
                      style: const TextStyle(color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) return;
                    final cat = cats.firstWhere((c) => c.id == selectedCatId);
                    
                    final updatedExpense = Expense(
                      id: expense.id,
                      categoryId: cat.id,
                      categoryNameSnapshot: cat.name,
                      amount: amount,
                      date: DateHelper.toDbDate(date),
                      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(), // تحديث الملاحظة
                      uuid: expense.uuid,
                      memberName: expense.memberName,
                      createdAt: expense.createdAt,
                    );

                    await provider.updateExpense(updatedExpense);
                    if (modalCtx.mounted) Navigator.pop(modalCtx);
                  },
                  child: const Text('حفظ التعديلات'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
