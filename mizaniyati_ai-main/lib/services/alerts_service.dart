import '../core/constants/app_constants.dart';
import '../core/db/database_helper.dart';
import '../core/utils/date_helper.dart';
import 'category_service.dart';

enum AlertSeverity { info, warning, danger }

class AlertItem {
  final String title;
  final String message;
  final AlertSeverity severity;
  final String? actionHint;

  const AlertItem({
    required this.title,
    required this.message,
    this.severity = AlertSeverity.info,
    this.actionHint,
  });
}

class AlertsService {
  final _db = DatabaseHelper.instance;
  final _cat = CategoryService();

  Future<List<AlertItem>> computeAll(int payDay) async {
    final alerts = <AlertItem>[];
    final (start, end) = DateHelper.currentPeriod(payDay);

    final totalIncome = await _db.getTotalIncome(start, end);
    final totalExpense = await _db.getTotalExpense(start, end);
    final ratio = totalIncome > 0 ? totalExpense / totalIncome : 0.0;

    if (totalIncome > 0 && ratio >= AppConstants.alertHighRatio) {
      alerts.add(AlertItem(
        title: ratio >= 1.0 ? 'تجاوزت دخلك!' : 'اقتربت من حد الدخل',
        message:
            'صرفت ${(ratio * 100).toStringAsFixed(0)}% من دخل الشهر. '
            'المتبقي: ${(totalIncome - totalExpense).toStringAsFixed(0)} ج.م',
        severity: ratio >= 1.0 ? AlertSeverity.danger : AlertSeverity.warning,
      ));
    }

    final categories = await _cat.getAll();
    for (final cat in categories) {
      if (cat.id == null) continue;

      if (cat.hasCap) {
        final currentTotal =
            await _db.getCategoryTotal(cat.id!, start, end);
        if (currentTotal > cat.cap!) {
          alerts.add(AlertItem(
            title: 'تجاوزت سقف ${cat.name}',
            message: 'صرفت ${currentTotal.toStringAsFixed(0)} من سقف '
                '${cat.cap!.toStringAsFixed(0)} ج.م',
            severity: AlertSeverity.danger,
          ));
        } else if (currentTotal >= cat.cap! * 0.85) {
          alerts.add(AlertItem(
            title: '${cat.name}: اقتربت من السقف',
            message:
                'استهلكت ${((currentTotal / cat.cap!) * 100).toStringAsFixed(0)}%',
            severity: AlertSeverity.warning,
          ));
        }
      }

      if (cat.isFixed) {
        final avg = await _db.getCategoryAverage3Months(cat.id!, payDay);
        if (avg != null && avg > 0) {
          final currentTotal =
              await _db.getCategoryTotal(cat.id!, start, end);
          if (currentTotal > avg * AppConstants.alertSpikeRatio) {
            alerts.add(AlertItem(
              title: '${cat.name}: ارتفاع غير معتاد',
              message: 'هذا الشهر: ${currentTotal.toStringAsFixed(0)} ج.م — '
                  'المعتاد: ${avg.toStringAsFixed(0)} ج.م',
              severity: AlertSeverity.warning,
            ));
          }
        }
      }
    }

    alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return alerts;
  }
}
