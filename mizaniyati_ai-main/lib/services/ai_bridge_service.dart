import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';

class AiBridgeService {
  Future<List<AiAppInfo>> detectInstalledApps() async {
    // نعرض القائمة المعروفة دائماً (أندرويد يمنع قراءة قائمة الحزم)
    final results = <AiAppInfo>[];
    for (final app in AppConstants.knownAiApps) {
      results.add(AiAppInfo(name: app['name']!, package: app['package']!));
    }
    return results;
  }

  Future<bool> openApp(String package) async {
    try {
      final uri = Uri.parse('https://play.google.com/store/apps/details?id=$package');
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> copyReportToClipboard(String report) async {
    await Clipboard.setData(ClipboardData(text: report));
  }

  String buildReport({
    required double totalIncome,
    required double totalExpense,
    required Map<String, double> categoryTotals,
    required Map<String, double> capsByCategory,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int payDay,
  }) {
    final net = totalIncome - totalExpense;
    final ratio = totalIncome > 0 ? (totalExpense / totalIncome * 100) : 0.0;
    final buf = StringBuffer();
    buf.writeln('أنت خبير في التخطيط المالي الشخصي. حلل البيانات التالية بالعربية وأعطني:');
    buf.writeln('1) تشخيصاً سريعاً للوضع المالي');
    buf.writeln('2) أكبر 3 بؤر إنفاق يجب معالجتها');
    buf.writeln('3) سيناريوهين واقعيين للتوفير');
    buf.writeln('4) توصيات عملية قابلة للتنفيذ');
    buf.writeln('');
    buf.writeln('--- بياناتي ---');
    buf.writeln('العملة: جنيه مصري (ج.م)');
    buf.writeln('يوم الراتب: $payDay');
    buf.writeln('إجمالي الدخل: ${totalIncome.toStringAsFixed(0)} ج.م');
    buf.writeln('إجمالي المصروفات: ${totalExpense.toStringAsFixed(0)} ج.م');
    buf.writeln('صافي الدخل: ${net.toStringAsFixed(0)} ج.م');
    buf.writeln('نسبة الإنفاق: ${ratio.toStringAsFixed(1)}%');
    buf.writeln('');
    buf.writeln('تفصيل الإنفاق حسب التصنيف:');
    final sorted = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      final cap = capsByCategory[e.key];
      final capStr = cap != null && cap > 0 ? ' (السقف: ${cap.toStringAsFixed(0)})' : '';
      buf.writeln('- ${e.key}: ${e.value.toStringAsFixed(0)} ج.م$capStr');
    }
    buf.writeln('');
    buf.writeln('ركّز على نصائح واقعية للاقتصاد المصري.');
    return buf.toString();
  }
}

class AiAppInfo {
  final String name;
  final String package;
  const AiAppInfo({required this.name, required this.package});
}
