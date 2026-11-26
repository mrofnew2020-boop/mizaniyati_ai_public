import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user_profile.dart';
import '../../providers/app_state.dart';
import '../../providers/profile_provider.dart';
import '../shared/widgets/gradient_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  final _nameCtrl = TextEditingController();
  final _payDayCtrl = TextEditingController(text: '1');
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _payDayCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedRole == null) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('يرجى إدخال الاسم');
      return;
    }

    // طلب الرقم السري إذا كان مديراً
    if (_selectedRole == AppConstants.roleManager) {
      final pinCtrl = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardElevated,
          title: const Text('الرقم السري للمدير', style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'أدخل الرقم السري (الافتراضي 1234)',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                if (pinCtrl.text == context.read<AppState>().pin) {
                  Navigator.pop(ctx, true);
                } else {
                  _snack('الرقم السري غير صحيح');
                }
              },
              child: const Text('دخول'),
            ),
          ],
        ),
      );
      if (result != true) return;
    }

    setState(() => _saving = true);
    final appState = context.read<AppState>();
    final profileProvider = context.read<ProfileProvider>();
    final payDay = int.tryParse(_payDayCtrl.text.trim()) ?? 1;
    await profileProvider.save(UserProfile(name: name, role: _selectedRole!));
    await appState.setUserName(name);
    if (_selectedRole == AppConstants.roleManager) {
      await appState.setPayDay(payDay);
    }
    await appState.setRole(_selectedRole!);
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isManagerSelected = _selectedRole == AppConstants.roleManager;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (rect) => AppColors.primaryGradient.createShader(rect),
                child: const Text('ميزانيتي AI',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              const Text('اختر دورك لتبدأ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              const SizedBox(height: 32),
              _roleCard(
                role: AppConstants.roleManager,
                icon: Icons.admin_panel_settings_outlined,
                title: 'مدير الميزانية',
                description: 'يدير الدخل والمصروفات، يحلل، ويستلم تقارير الأسرة',
              ),
              const SizedBox(height: 14),
              _roleCard(
                role: AppConstants.roleRecorder,
                icon: Icons.edit_note,
                title: 'مسجّل مصروفات',
                description: 'يسجّل مصروفاته اليومية ويرسلها لمدير الميزانية',
              ),
              const SizedBox(height: 28),
              const Text('اسمك',
                style: TextStyle(color: AppColors.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'مثال: أحمد',
                  prefixIcon: Icon(Icons.person_outline)),
              ),
              if (isManagerSelected) ...[
                const SizedBox(height: 16),
                const Text('يوم الراتب (1-28)',
                  style: TextStyle(color: AppColors.textSecondary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _payDayCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '1',
                    prefixIcon: Icon(Icons.calendar_today_outlined)),
                ),
              ],
              const SizedBox(height: 32),
              GradientButton(
                label: 'بدء الاستخدام',
                icon: Icons.arrow_forward,
                loading: _saving,
                onPressed: _selectedRole != null ? _confirm : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String role,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue.withOpacity(0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.divider,
            width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                color: selected ? null : AppColors.cardElevated,
                borderRadius: BorderRadius.circular(14)),
              child: Icon(icon,
                color: selected ? Colors.white : AppColors.textSecondary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(color: AppColors.textPrimary,
                      fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(description,
                    style: const TextStyle(color: AppColors.textSecondary,
                      fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 22),
          ],
        ),
      ),
    );
  }
}
