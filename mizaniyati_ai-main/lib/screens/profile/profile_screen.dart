import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_profile.dart';
import '../../providers/app_state.dart';
import '../../providers/profile_provider.dart';
import '../shared/widgets/gradient_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String? _imagePath;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await context.read<ProfileProvider>().getProfile();
    if (p != null) {
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone ?? '';
      _emailCtrl.text = p.email ?? '';
      _imagePath = p.imagePath;
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (x == null) return;
    final provider = context.read<ProfileProvider>();
    final saved = await provider.persistImage(x.path);
    if (mounted) setState(() => _imagePath = saved);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final appState = context.read<AppState>();
    final role = appState.role ?? 'manager';
    final profile = UserProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      imagePath: _imagePath, role: role);
    await context.read<ProfileProvider>().save(profile);
    await appState.setUserName(profile.name);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.success, content: Text('تم الحفظ ✓')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.cardElevated,
                      backgroundImage: _imagePath != null ? FileImage(File(_imagePath!)) : null,
                      child: _imagePath == null
                        ? const Icon(Icons.person, size: 50, color: AppColors.textMuted)
                        : null),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'الاسم', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'الهاتف', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 24),
            GradientButton(label: 'حفظ التغييرات',
              icon: Icons.check, loading: _saving, onPressed: _save),
            const SizedBox(height: 32),
            _info(icon: Icons.security, title: 'الخصوصية',
              subtitle: 'كل بياناتك محفوظة محلياً على هذا الجهاز فقط'),
            _info(icon: Icons.account_circle_outlined, title: 'الدور الحالي',
              subtitle: context.watch<AppState>().isManager
                ? 'مدير الميزانية' : 'مسجّل مصروفات'),
          ],
        ),
      ),
    );
  }

  Widget _info({required IconData icon, required String title, required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card,
        borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
