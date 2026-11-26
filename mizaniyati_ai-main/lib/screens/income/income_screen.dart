import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../models/income_entry.dart';
import '../../models/income_source.dart';
import '../../providers/income_provider.dart';
import '../shared/widgets/gradient_button.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncomeProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدخل'),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryBlue,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [Tab(text: 'العمليات'), Tab(text: 'المصادر')],
          ),
        ),
        body: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _summary(provider.periodTotal),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _entries(context, provider),
                        _sources(context, provider),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addEntry(context),
          backgroundColor: AppColors.primaryBlue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _summary(double t) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            const Text('إجمالي دخل الشهر',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text(CurrencyFormatter.format(t),
              style: const TextStyle(color: Colors.white,
                fontSize: 28, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _entries(BuildContext context, IncomeProvider p) {
    if (p.periodEntries.isEmpty) {
      return const Center(
        child: Text('لا توجد عمليات دخل هذا الشهر',
          style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: p.periodEntries.length,
      itemBuilder: (_, i) {
        final e = p.periodEntries[i];
        return Dismissible(
          key: Key('income-${e.id}'),
          background: Container(
            color: AppColors.danger,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white)),
          confirmDismiss: (_) => _confirm(context),
          onDismissed: (_) => p.deleteEntry(e.id!),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(e.sourceNameSnapshot,
                style: const TextStyle(color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600)),
              subtitle: Text(
                DateHelper.formatArabic(DateTime.parse(e.date)),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              trailing: Text(CurrencyFormatter.formatShort(e.amount),
                style: const TextStyle(color: AppColors.success,
                  fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        );
      },
    );
  }

  Widget _sources(BuildContext context, IncomeProvider p) {
    return Column(
      children: [
        Expanded(
          child: p.sources.isEmpty
              ? const Center(
                  child: Text('لم تضف أي مصدر دخل',
                    style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: p.sources.length,
                  itemBuilder: (_, i) {
                    final s = p.sources[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                          child: Icon(_icon(s.type),
                            color: AppColors.primaryBlue, size: 20),
                        ),
                        title: Text(s.name,
                          style: const TextStyle(color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${s.type}${s.payDay != null ? " · يوم ${s.payDay}" : ""}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.archive_outlined,
                            color: AppColors.textMuted, size: 20),
                          onPressed: () => p.archiveSource(s.id!)),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            label: 'إضافة مصدر دخل',
            icon: Icons.add,
            onPressed: () => _addSource(context)),
        ),
      ],
    );
  }

  IconData _icon(String type) => switch (type) {
        'ثابت' => Icons.work_outline,
        'متغير' => Icons.trending_up,
        _ => Icons.more_horiz,
      };

  Future<bool> _confirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.cardElevated,
            title: const Text('حذف العملية',
              style: TextStyle(color: AppColors.textPrimary)),
            content: const Text('هل تريد حذف عملية الدخل هذه؟',
              style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف',
                  style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ) ?? false;
  }

  Future<void> _addSource(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final payDayCtrl = TextEditingController();
    String type = 'ثابت';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardElevated,
          title: const Text('مصدر دخل جديد',
            style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl,
                  decoration: const InputDecoration(hintText: 'الاسم')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  dropdownColor: AppColors.cardElevated,
                  items: AppConstants.incomeTypes.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setS(() => type = v!),
                  decoration: const InputDecoration(hintText: 'النوع')),
                if (type == 'ثابت') ...[
                  const SizedBox(height: 10),
                  TextField(controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'المبلغ الافتراضي')),
                  const SizedBox(height: 10),
                  TextField(controller: payDayCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'يوم الراتب (1-28)')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final s = IncomeSource(
                  name: nameCtrl.text.trim(), type: type,
                  defaultAmount: double.tryParse(amountCtrl.text.trim()),
                  payDay: int.tryParse(payDayCtrl.text.trim()),
                  createdAt: DateTime.now().toIso8601String());
                await ctx.read<IncomeProvider>().addSource(s);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }

  Future<void> _addEntry(BuildContext context) async {
    final p = context.read<IncomeProvider>();
    if (p.sources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف مصدر دخل أولاً')));
      return;
    }
    IncomeSource sel = p.sources.first;
    final amountCtrl = TextEditingController(
      text: sel.defaultAmount?.toStringAsFixed(0) ?? '');
    DateTime date = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardElevated,
          title: const Text('تسجيل دخل',
            style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<IncomeSource>(
                value: sel,
                dropdownColor: AppColors.cardElevated,
                items: p.sources.map((s) =>
                  DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) => setS(() {
                  sel = v!;
                  if (sel.defaultAmount != null) {
                    amountCtrl.text = sel.defaultAmount!.toStringAsFixed(0);
                  }
                }),
                decoration: const InputDecoration(hintText: 'المصدر')),
              const SizedBox(height: 10),
              TextField(controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'المبلغ')),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx, initialDate: date,
                    firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (picked != null) setS(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(DateHelper.formatArabic(date),
                    style: const TextStyle(color: AppColors.textPrimary))),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                final a = double.tryParse(amountCtrl.text.trim());
                if (a == null || a <= 0) return;
                await ctx.read<IncomeProvider>().addEntry(IncomeEntry(
                  sourceId: sel.id, sourceNameSnapshot: sel.name,
                  amount: a, date: DateHelper.toDbDate(date),
                  createdAt: DateTime.now().toIso8601String()));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}
