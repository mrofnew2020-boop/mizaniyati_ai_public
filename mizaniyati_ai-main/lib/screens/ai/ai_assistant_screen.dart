import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/app_state.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/income_provider.dart';
import '../../services/ai_bridge_service.dart';
import '../shared/widgets/gradient_button.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _svc = AiBridgeService();
  List<AiAppInfo> _apps = [];
  bool _detecting = true;
  bool _building = false;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    final apps = await _svc.detectInstalledApps();
    if (mounted) setState(() { _apps = apps; _detecting = false; });
  }

  Future<void> _buildAndCopy() async {
    setState(() => _building = true);
    final income = context.read<IncomeProvider>().periodTotal;
    final expense = context.read<ExpenseProvider>();
    final categories = context.read<CategoryProvider>();
    final payDay = context.read<AppState>().payDay;

    final (start, end) = DateHelper.currentPeriod(payDay);
    final catTotals = <String, double>{};
    final caps = <String, double>{};
    for (final e in expense.categoryTotals.entries) {
      final c = categories.byId(e.key);
      if (c == null) continue;
      catTotals[c.name] = e.value;
      if (c.hasCap) caps[c.name] = c.cap!;
    }

    final report = _svc.buildReport(
      totalIncome: income, totalExpense: expense.periodTotal,
      categoryTotals: catTotals, capsByCategory: caps,
      periodStart: start, periodEnd: end, payDay: payDay);

    await _svc.copyReportToClipboard(report);
    if (mounted) {
      setState(() => _building = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('تم نسخ التقرير ✓ — الصقه في أي تطبيق AI')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستشار الذكي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.white, size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('مستشارك المالي بالذكاء الاصطناعي',
                          style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('يحلل بياناتك ويقترح سيناريوهات توفير واقعية',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('الخطوة 1: أنشئ التقرير',
              style: TextStyle(color: AppColors.textPrimary,
                fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card,
                borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سيتم إنشاء ملخص مالي ونسخه للحافظة. لن يُرسل أي شيء تلقائياً.',
                    style: TextStyle(color: AppColors.textSecondary,
                      fontSize: 13, height: 1.5)),
                  const SizedBox(height: 14),
                  GradientButton(
                    label: 'توليد التقرير ونسخه',
                    icon: Icons.auto_awesome, loading: _building,
                    onPressed: _buildAndCopy),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('الخطوة 2: افتح تطبيق AI',
              style: TextStyle(color: AppColors.textPrimary,
                fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (_detecting)
              const Center(child: CircularProgressIndicator())
            else
              ..._apps.map((app) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.chat_bubble_outline,
                      color: AppColors.primaryPink, size: 20)),
                  title: Text(app.name,
                    style: const TextStyle(color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
                  subtitle: const Text('اضغط لفتح التطبيق',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new,
                    color: AppColors.primaryBlue, size: 18),
                  onTap: () => _svc.openApp(app.package),
                ),
              )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
