import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _fmt = NumberFormat('#,##0.00', 'en_US');
  static final _fmtInt = NumberFormat('#,##0', 'en_US');

  static String format(double amount) {
    if (amount == amount.roundToDouble()) {
      return '${_fmtInt.format(amount)} ج.م';
    }
    return '${_fmt.format(amount)} ج.م';
  }

  static String formatInt(double amount) => '${_fmtInt.format(amount)} ج.م';

  static String formatShort(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} مليون ج.م';
    }
    if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} ألف ج.م';
    }
    return '${amount.toStringAsFixed(0)} ج.م';
  }
}
