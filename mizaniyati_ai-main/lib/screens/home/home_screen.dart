import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/db/database_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../models/expense.dart';
import '../../providers/app_state.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../services/alerts_service.dart';
import '../analysis/analysis_screen.dart';
import '../expenses/expense_history_screen.dart';
import '../income/income_screen.dart';
import '../shared/widgets/app_drawer.dart';
import '../shared/widgets/glass_bottom_nav.dart';
import 'widgets/balance_ring.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlertItem> _alerts = [];
  bool _initialLoad = true;
  
  // متغيرات الميزانية اليومية
  double? _dailyBudget;
  int _daysRemaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final appState = context.read<AppState>();
    await Future.wait([
      context.read<CategoryProvider>().load(),
      context.read<IncomeProvider>().load(appState.payDay),
      context.read<ExpenseProvider>().load(appState.payDay),
    ]);
    
    await _calculateDailyBudget();
    await _refreshAlerts();
    
    if (mounted) setState(() => _initialLoad = false);
  }

  Future<void> _calculateDailyBudget() async {
    final income = context.read<IncomeProvider>().periodTotal;
    final expense = context.read<ExpenseProvider>().periodTotal;
    
    final firstFixedDate = await DatabaseHelper.instance.getFirstFixedIncomeDate();
    
    if (firstFixedDate != null) {
      final daysPassed = DateTime.now().difference(firstFixedDate).inDays;
      // نحسب الأيام المتبقية من 30
      int remaining = 30 - daysPassed;
      if (remaining <= 0) remaining = 1; // تجنب القسمة على صفر
      
      final net = income - expense;
      
      setState(() {
        _daysRemaining = remaining;
        _dailyBudget = net / remaining;
      });
    } else {
      setState(() {
        _dailyBudget = null; // لا يوجد دخل ثابت بعد
      });
    }
  }

  Future<void> _refreshAlerts() async {
    final alerts = await AlertsService().computeAll(context.read<AppState>().payDay);
    if (mounted) setState(() => _alerts = alerts);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final income = context.watch<IncomeProvider>().periodTotal;
    final expense = context.watch<ExpenseProvider>();
    final isManager = appState.isManager;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('ميزانيتي AI'),
        actions: [
          if (_alerts.isNotEmpty)
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryPink, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('${_alerts.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              onPressed: () => _showAlertsSheet(context),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const IncomeScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen()));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalysisScreen()));
        },
        onAddTap: () => _showQuickAdd(context),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: AppColors.card.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          BalanceRing(income: income, expense: expense.periodTotal),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                _miniStat(label: 'الدخل', value: income,
                                  color: AppColors.success, icon: Icons.arrow_downward),
                                const SizedBox(width: 10),
                                _miniStat(label: 'المصروف', value: expense.periodTotal,
                                  color: AppColors.primaryPink, icon: Icons.arrow_upward),
                              ],
                            ),
                          ),
                          
                          // ===== بطاقة الميزانية اليومية الجديدة =====
                          if (_dailyBudget != null) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.cardElevated.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.calendar_today, color: AppColors.primaryBlue, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('الميزانية اليومية الآمنة',
                                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                          const SizedBox(height: 2),
                                          Text(
                                            _dailyBudget! < 0 ? 'عجز' : '${CurrencyFormatter.formatShort(_dailyBudget!)} / يوم',
                                            style: TextStyle(
                                              color: _dailyBudget! < 0 ? AppColors.danger : AppColors.primaryBlue,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('متبقي $_daysRemaining يوماً',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                        const SizedBox(height: 2),
                                        const Text('من أصل 30',
                                          style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // ============================================
                          
                        ],
                      ),
                    ),
                    if (_alerts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text('التنبيهات',
                        style: TextStyle(color: AppColors.textPrimary,
                          fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      ..._alerts.take(3).map(_alertCard),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('آخر المصروفات',
                          style: TextStyle(color: AppColors.textPrimary,
                            fontSize: 16, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (isManager)
                          TextButton(
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen())),
                            child: const Text('عرض الكل')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (expense.recentExpenses.isEmpty)
                      _emptyCard('لم تسجل أي مصروف بعد')
                    else
                      ...expense.recentExpenses.take(5).map(_expenseTile),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _miniStat({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardElevated.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Text(CurrencyFormatter.formatShort(value),
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _alertCard(AlertItem alert) {
    final color = switch (alert.severity) {
      AlertSeverity.danger => AppColors.danger,
      AlertSeverity.warning => AppColors.warning,
      AlertSeverity.info => AppColors.primaryBlue,
    };
    final icon = switch (alert.severity) {
      AlertSeverity.danger => Icons.error_outline,
      AlertSeverity.warning => Icons.warning_amber_rounded,
      AlertSeverity.info => Icons.info_outline,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                  style: TextStyle(color: color,
                    fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(alert.message,
                  style: const TextStyle(color: AppColors.textSecondary,
                    fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseTile(Expense e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long,
              color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.categoryNameSnapshot,
                  style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 14, fontWeight: FontWeight.w600)),
                if (e.note != null && e.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(e.note!,
                    style: const TextStyle(color: AppColors.primaryBlue,
                      fontSize: 11, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 2),
                Text(DateHelper.formatArabic(DateTime.parse(e.date)),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
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

  Widget _emptyCard(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 42),
            const SizedBox(height: 8),
            Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );

  void _showAlertsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('كل التنبيهات',
              style: TextStyle(color: AppColors.textPrimary,
                fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ..._alerts.map(_alertCard),
          ],
        ),
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
              const Text('إضافة مصروف سريع',
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
                    
                    final status = await context.read<ExpenseProvider>().addExpense(
                      categoryId: cat.id!, 
                      categoryName: cat.name,
                      amount: amount, 
                      date: DateTime.now(),
                      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      memberName: context.read<AppState>().userName);
                      
                    if (!modalCtx.mounted) return;
                    Navigator.pop(modalCtx);
                    await _loadAll(); // تحديث كل شيء بما في ذلك الميزانية اليومية
                    if (status != null && status.exceeded && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: AppColors.warning,
                        content: Text('تنبيه: تجاوزت سقف ${cat.name} — الفائض '
                          '${(status.currentTotal - status.cap).toStringAsFixed(0)} ج.م')));
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
