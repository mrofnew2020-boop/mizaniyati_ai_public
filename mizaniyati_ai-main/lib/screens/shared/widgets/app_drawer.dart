import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/app_state.dart';
import '../../analysis/analysis_screen.dart';
import '../../ai/ai_assistant_screen.dart';
import '../../expenses/expenses_screen.dart';
import '../../expenses/expense_history_screen.dart'; // تمت الإضافة هنا
import '../../import/import_review_screen.dart';
import '../../income/income_screen.dart';
import '../../profile/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isManager = appState.isManager;
    final name = appState.userName.isNotEmpty
        ? appState.userName
        : (isManager ? 'مدير الميزانية' : 'عضو');

    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30, backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 34)),
                  const SizedBox(height: 12),
                  Text(name,
                    style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      isManager ? 'مدير الميزانية' : 'مسجّل مصروفات',
                      style: const TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _item(context, icon: Icons.dashboard_outlined, label: 'الرئيسية',
              onTap: () => Navigator.pop(context)),
            if (isManager) ...[
              _item(context, icon: Icons.trending_up, label: 'الدخل',
                screen: const IncomeScreen()),
              _item(context, icon: Icons.shopping_cart_outlined, label: 'المصروفات',
                screen: const ExpensesScreen()),
              // تمت إضافة زر السجل هنا بالضبط
              _item(context, icon: Icons.history, label: 'سجل المصروفات',
                screen: const ExpenseHistoryScreen()),
              _item(context, icon: Icons.analytics_outlined, label: 'التحليل',
                screen: const AnalysisScreen()),
              _item(context, icon: Icons.auto_awesome, label: 'المستشار الذكي',
                screen: const AiAssistantScreen()),
              _item(context, icon: Icons.download_outlined, label: 'استيراد مصروفات',
                screen: const ImportReviewScreen()),
            ] else ...[
              _item(context, icon: Icons.shopping_cart_outlined, label: 'المصروفات',
                screen: const ExpensesScreen()),
            ],
            _item(context, icon: Icons.person_outline, label: 'الملف الشخصي',
              screen: const ProfileScreen()),
            const Spacer(),
            const Divider(),
            _item(context, icon: Icons.logout, label: 'تغيير الدور',
              onTap: () async {
                await context.read<AppState>().resetRole();
                if (context.mounted) Navigator.pop(context);
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    Widget? screen,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
    );
  }
}
