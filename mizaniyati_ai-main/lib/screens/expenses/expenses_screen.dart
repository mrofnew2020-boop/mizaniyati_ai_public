import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/expense_category.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../shared/widgets/gradient_button.dart';

const _iconOptions = [
  'restaurant', 'shopping_basket', 'directions_car', 'receipt_long',
  'home', 'bolt', 'local_fire_department', 'water_drop', 'wifi',
  'medical_services', 'school', 'movie', 'checkroom', 'more_horiz',
  'pets', 'sports_esports', 'flight', 'card_giftcard',
];

IconData _iconFrom(String n) => switch (n) {
  'restaurant' => Icons.restaurant, 'shopping_basket' => Icons.shopping_basket,
  'directions_car' => Icons.directions_car, 'receipt_long' => Icons.receipt_long,
  'home' => Icons.home, 'bolt' => Icons.bolt,
  'local_fire_department' => Icons.local_fire_department,
  'water_drop' => Icons.water_drop, 'wifi' => Icons.wifi,
  'medical_services' => Icons.medical_services, 'school' => Icons.school,
  'movie' => Icons.movie, 'checkroom' => Icons.checkroom,
  'pets' => Icons.pets, 'sports_esports' => Icons.sports_esports,
  'flight' => Icons.flight, 'card_giftcard' => Icons.card_giftcard,
  _ => Icons.more_horiz,
};

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CategoryProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المصروفات'),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryPink,
            labelColor: AppColors.primaryPink,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [Tab(text: 'التصنيفات'), Tab(text: 'الأرشيف')],
          ),
        ),
        body: cp.loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [
                _list(context, cp, archived: false),
                _list(context, cp, archived: true),
              ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _sheet(context),
          backgroundColor: AppColors.primaryPink,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('تصنيف', style: TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _list(BuildContext context, CategoryProvider cp, {required bool archived}) {
    final items = archived
        ? cp.categories.where((c) => c.archived).toList()
        : cp.categories;
    if (items.isEmpty) {
      return Center(
        child: Text(archived ? 'لا يوجد مؤرشف' : 'لا يوجد تصنيفات',
          style: const TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _tile(context, items[i], cp, archived));
  }

  Widget _tile(BuildContext context, ExpenseCategory c, CategoryProvider cp, bool archived) {
    final exp = context.watch<ExpenseProvider>();
    final cap = exp.capStatuses[c.id];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(_iconFrom(c.icon),
                    color: AppColors.primaryPink, size: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                        style: const TextStyle(color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(c.isFixed ? 'ثابت' : 'متغير',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.cardElevated,
                  onSelected: (v) async {
                    switch (v) {
                      case 'edit': _sheet(context, existing: c); break;
                      case 'archive': await cp.archiveCategory(c.id!); break;
                      case 'restore': await cp.restoreCategory(c.id!); break;
                      case 'delete': await _delete(context, c, cp); break;
                    }
                  },
                  itemBuilder: (_) => [
                    if (!archived) const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    if (!archived) const PopupMenuItem(value: 'archive', child: Text('أرشفة')),
                    if (archived) const PopupMenuItem(value: 'restore', child: Text('استعادة')),
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ]),
              ],
            ),
            if (c.hasCap && cap != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: cap.ratio.clamp(0.0, 1.0), minHeight: 8,
                  backgroundColor: AppColors.cardElevated,
                  valueColor: AlwaysStoppedAnimation(
                    cap.ratio >= 1 ? AppColors.danger :
                    cap.ratio >= 0.85 ? AppColors.warning : AppColors.primaryPink))),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(CurrencyFormatter.formatInt(cap.currentTotal),
                    style: TextStyle(
                      color: cap.ratio >= 1 ? AppColors.danger : AppColors.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                  const Text(' / ', style: TextStyle(color: AppColors.textMuted)),
                  Text(CurrencyFormatter.formatInt(cap.cap),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const Spacer(),
                  Text('${(cap.ratio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: cap.ratio >= 1 ? AppColors.danger : AppColors.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, ExpenseCategory c, CategoryProvider cp) async {
    final count = await cp.countExpenses(c.id!);
    if (!context.mounted) return;
    if (count == 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardElevated,
          title: const Text('حذف التصنيف',
            style: TextStyle(color: AppColors.textPrimary)),
          content: Text('حذف "${c.name}" نهائياً؟',
            style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: AppColors.danger))),
          ]));
      if (ok == true) {
        await cp.deleteWithTransfer(categoryId: c.id!, targetCategoryId: null);
      }
      return;
    }

    final others = cp.categories.where((x) => x.id != c.id).toList();
    if (others.isEmpty) return;
    ExpenseCategory target = others.firstWhere((x) => x.name == 'أخرى',
      orElse: () => others.first);

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.cardElevated,
          title: const Text('نقل المصروفات',
            style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('لدى "${c.name}" \$count مصروفاً. اختر تصنيفاً لنقلها:',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpenseCategory>(
                value: target,
                dropdownColor: AppColors.cardElevated,
                items: others.map((t) => DropdownMenuItem(
                  value: t, child: Text(t.name))).toList(),
                onChanged: (v) => setS(() => target = v!),
                decoration: const InputDecoration(hintText: 'التصنيف البديل')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('نقل وحذف')),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await cp.deleteWithTransfer(categoryId: c.id!, targetCategoryId: target.id);
    }
  }

  Future<void> _sheet(BuildContext context, {ExpenseCategory? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final capCtrl = TextEditingController(text: existing?.cap?.toStringAsFixed(0) ?? '');
    String type = existing?.type ?? 'variable';
    String icon = existing?.icon ?? 'more_horiz';
    String capMode = existing?.capMode ?? 'manual';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setS) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'تصنيف جديد' : 'تعديل التصنيف',
                  style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(controller: nameCtrl,
                  decoration: const InputDecoration(hintText: 'اسم التصنيف')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  dropdownColor: AppColors.cardElevated,
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('ثابت')),
                    DropdownMenuItem(value: 'variable', child: Text('متغير')),
                  ],
                  onChanged: (v) => setS(() => type = v!),
                  decoration: const InputDecoration(hintText: 'النوع')),
                const SizedBox(height: 10),
                TextField(controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'سقف شهري (اختياري)',
                    prefixIcon: Icon(Icons.flag_outlined))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: capMode,
                  dropdownColor: AppColors.cardElevated,
                  items: const [
                    DropdownMenuItem(value: 'manual', child: Text('سقف يدوي')),
                    DropdownMenuItem(value: 'auto', child: Text('تلقائي (متوسط 3 أشهر)')),
                  ],
                  onChanged: (v) => setS(() => capMode = v!),
                  decoration: const InputDecoration(hintText: 'طريقة السقف')),
                const SizedBox(height: 16),
                const Text('الأيقونة',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _iconOptions.map((ic) {
                    final sel = icon == ic;
                    return GestureDetector(
                      onTap: () => setS(() => icon = ic),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primaryPink.withOpacity(0.2) : AppColors.cardElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: sel ? Border.all(color: AppColors.primaryPink) : null),
                        child: Icon(_iconFrom(ic),
                          color: sel ? AppColors.primaryPink : AppColors.textSecondary,
                          size: 22)));
                  }).toList()),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'حفظ',
                  onPressed: () async {
                    final n = nameCtrl.text.trim();
                    if (n.isEmpty) return;
                    final cap = double.tryParse(capCtrl.text.trim());
                    final cp = context.read<CategoryProvider>();
                    if (existing == null) {
                      final id = await cp.addCategory(
                        name: n, type: type, icon: icon, cap: cap, capMode: capMode);
                      if (id == -1 && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الاسم مستخدم')));
                        return;
                      }
                    } else {
                      final ok = await cp.updateCategory(existing.copyWith(
                        name: n, type: type, icon: icon, cap: cap,
                        clearCap: cap == null, capMode: capMode));
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الاسم مستخدم')));
                        return;
                      }
                    }
                    if (modalCtx.mounted) Navigator.pop(modalCtx);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
