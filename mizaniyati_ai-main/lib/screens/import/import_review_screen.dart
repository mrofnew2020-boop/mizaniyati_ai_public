import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/app_state.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/export_import_service.dart';
import '../shared/widgets/gradient_button.dart';

class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({super.key});
  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  final _svc = ExportImportService();
  ImportPreview? _preview;
  Set<String> _selected = {};
  bool _loading = false;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['json']);
    if (res == null || res.files.isEmpty) return;
    final path = res.files.first.path;
    if (path == null) return;
    setState(() => _loading = true);
    final preview = await _svc.previewImport(path);
    if (mounted) {
      setState(() {
        _preview = preview;
        _selected = {
          ...?preview?.candidates.where((c) => c.status == ImportStatus.fresh).map((c) => c.uuid),
        };
        _loading = false;
      });
      if (preview == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ملف غير صالح')));
      }
    }
  }

  Future<void> _commit() async {
    if (_preview == null) return;
    setState(() => _loading = true);
    final catProvider = context.read<CategoryProvider>();
    final result = await _svc.commitImport(
      preview: _preview!, selectedUuids: _selected,
      resolveCategoryId: (name) async {
        final ex = catProvider.categories.where((c) => c.name == name).toList();
        if (ex.isNotEmpty) return ex.first.id;
        final id = await catProvider.addCategory(
          name: name, type: 'variable', icon: 'more_horiz');
        return id > 0 ? id : null;
      });
    if (mounted) {
      setState(() {
        _loading = false;
        _preview = null;
        _selected = {};
      });
      await context.read<ExpenseProvider>().load(context.read<AppState>().payDay);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.success,
          content: Text('استوردت ${result.imported}، تخطيت ${result.skipped}')));
      }
    }
  }

  Future<void> _export() async {
    final appState = context.read<AppState>();
    final (start, end) = DateHelper.currentPeriod(appState.payDay);
    final file = await _svc.exportPeriod(
      memberName: appState.userName.isEmpty ? 'مستخدم' : appState.userName,
      start: start, end: end, roleHint: appState.role);
    if (mounted) {
      await Share.shareXFiles([XFile(file.path)], subject: 'تصدير مصروفاتي');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الاستيراد والتصدير')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _preview == null ? _initial() : _previewUI(),
    );
  }

  Widget _initial() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(icon: Icons.upload_file, title: 'استيراد من عضو آخر',
              subtitle: 'اختر ملف JSON لمراجعته قبل الإضافة',
              actionLabel: 'اختيار ملف', onPressed: _pick),
            const SizedBox(height: 16),
            _card(icon: Icons.ios_share, title: 'تصدير مصروفاتي',
              subtitle: 'أرسل مصروفات الشهر الحالي عبر واتساب أو تلجرام',
              actionLabel: 'تصدير ومشاركة', onPressed: _export),
          ],
        ),
      );

  Widget _card({required IconData icon, required String title,
      required String subtitle, required String actionLabel, required VoidCallback onPressed}) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 32),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: AppColors.textPrimary,
              fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary,
              fontSize: 13, height: 1.5)),
            const SizedBox(height: 16),
            GradientButton(label: actionLabel, onPressed: onPressed),
          ],
        ),
      );

  Widget _previewUI() {
    final p = _preview!;
    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          color: AppColors.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('من: ${p.memberName}',
                style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('صُدّر: ${DateHelper.formatArabic(p.exportedAt)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              Row(children: [
                _chip('جديد', p.freshCount, AppColors.success),
                const SizedBox(width: 8),
                _chip('مكرر', p.duplicateCount, AppColors.textMuted),
                const SizedBox(width: 8),
                _chip('مشتبه', p.suspectCount, AppColors.warning),
              ]),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: p.candidates.length,
            itemBuilder: (_, i) {
              final c = p.candidates[i];
              final disabled = c.status == ImportStatus.duplicate;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: _selected.contains(c.uuid),
                  onChanged: disabled ? null : (v) => setState(() {
                    if (v == true) { _selected.add(c.uuid); }
                    else { _selected.remove(c.uuid); }
                  }),
                  activeColor: AppColors.primaryBlue,
                  title: Text(c.category, style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${DateHelper.formatArabic(DateTime.parse(c.date))}'
                    '${c.matchedNote != null ? " · ${c.matchedNote}" : ""}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  secondary: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(CurrencyFormatter.formatShort(c.amount),
                        style: const TextStyle(color: AppColors.primaryPink,
                          fontWeight: FontWeight.w700, fontSize: 14)),
                      _badge(c.status),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            label: 'استيراد ${_selected.length} مصروف',
            icon: Icons.download_done,
            onPressed: _selected.isEmpty ? null : _commit),
        ),
      ],
    );
  }

  Widget _chip(String l, int c, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text('\$l: \$c',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)));

  Widget _badge(ImportStatus s) {
    final (l, c) = switch (s) {
      ImportStatus.fresh => ('جديد', AppColors.success),
      ImportStatus.duplicate => ('مكرر', AppColors.textMuted),
      ImportStatus.suspect => ('مشتبه', AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(l, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)));
  }
}
