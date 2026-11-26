import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/db/database_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/app_state.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exp = context.watch<ExpenseProvider>();
    final cat = context.watch<CategoryProvider>();
    final payDay = context.watch<AppState>().payDay;

    final labels = <String>[];
    final values = <double>[];
    final colors = <Color>[
      AppColors.primaryBlue, AppColors.primaryPink, AppColors.success,
      AppColors.warning, const Color(0xFF9B5DE5), const Color(0xFF00BBF9),
    ];

    final sorted = exp.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      final c = cat.byId(e.key);
      labels.add(c?.name ?? 'أخرى');
      values.add(e.value);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('التحليل')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _stat('إجمالي الشهر',
                  CurrencyFormatter.formatShort(exp.periodTotal), AppColors.primaryPink)),
                const SizedBox(width: 10),
                Expanded(child: _stat('عدد التصنيفات',
                  '${exp.categoryTotals.length}', AppColors.primaryBlue)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('توزيع المصروفات',
              style: TextStyle(color: AppColors.textPrimary,
                fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (values.isEmpty)
              _empty()
            else
              _pie(values, colors, labels),
            const SizedBox(height: 24),
            const Text('تتبع تصنيف عبر الزمن',
              style: TextStyle(color: AppColors.textPrimary,
                fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _timeTracker(context, cat, exp, payDay),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color c) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card,
          borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _empty() => Container(
        height: 180, alignment: Alignment.center,
        child: const Text('لا توجد بيانات',
          style: TextStyle(color: AppColors.textSecondary)));

  Widget _pie(List<double> values, List<Color> colors, List<String> labels) {
    final total = values.fold<double>(0, (s, v) => s + v);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card,
        borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(PieChartData(
              sectionsSpace: 3, centerSpaceRadius: 55,
              sections: List.generate(values.length, (i) {
                final pct = total > 0 ? values[i] / total * 100 : 0;
                return PieChartSectionData(
                  value: values[i], color: colors[i % colors.length],
                  radius: 55, title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 11));
              }))),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12, runSpacing: 8,
            children: List.generate(values.length, (i) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${labels[i]} (${CurrencyFormatter.formatShort(values[i])})',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ]))),
        ],
      ),
    );
  }

  Widget _timeTracker(BuildContext context, CategoryProvider cat,
      ExpenseProvider exp, int payDay) {
    final cats = cat.categories
      .where((c) => (exp.categoryTotals[c.id] ?? 0) > 0).toList();
    if (cats.isEmpty) {
      return const SizedBox.shrink();
    }
    return _LineTracker(categoryId: cats.first.id!, payDay: payDay, categories: cats);
  }
}

class _LineTracker extends StatefulWidget {
  final int categoryId;
  final int payDay;
  final List categories;
  const _LineTracker({required this.categoryId, required this.payDay, required this.categories});
  @override
  State<_LineTracker> createState() => _LineTrackerState();
}

class _LineTrackerState extends State<_LineTracker> {
  List<double> _values = [];
  bool _loading = true;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.categoryId;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    final map = await db.getCategoryTotalsForPeriods(_selected, widget.payDay, 6);
    final list = <double>[];
    for (int i = 5; i >= 0; i--) {
      list.add(map[i] ?? 0);
    }
    if (mounted) setState(() {
      _values = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card,
        borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            value: _selected,
            dropdownColor: AppColors.cardElevated,
            items: widget.categories.map<DropdownMenuItem<int>>((c) =>
              DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) {
              setState(() => _selected = v!);
              _load();
            },
            decoration: const InputDecoration(hintText: 'اختر تصنيفاً')),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _values.every((v) => v == 0)
                ? const Center(child: Text('لا توجد بيانات',
                    style: TextStyle(color: AppColors.textSecondary)))
                : LineChart(LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(_values.length,
                          (i) => FlSpot(i.toDouble(), _values[i])),
                        isCurved: true,
                        gradient: AppColors.primaryGradient,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue.withOpacity(0.3),
                              AppColors.primaryPink.withOpacity(0.05)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter))),
                    ],
                  )),
          ),
        ],
      ),
    );
  }
}
