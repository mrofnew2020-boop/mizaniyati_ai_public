class DateHelper {
  DateHelper._();

  static String toDbDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime fromDbDate(String s) => DateTime.parse(s);

  static DateTime _safeDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }

  static DateTime periodStart(int payDay, {DateTime? ref}) {
    final r = ref ?? DateTime.now();
    if (r.day >= payDay) {
      return _safeDay(r.year, r.month, payDay);
    }
    return _safeDay(r.year, r.month - 1, payDay);
  }

  static DateTime periodEnd(int payDay, {DateTime? ref}) {
    final start = periodStart(payDay, ref: ref);
    final nextStart = _safeDay(start.year, start.month + 1, payDay);
    return nextStart.subtract(const Duration(days: 1));
  }

  static (DateTime, DateTime) currentPeriod(int payDay, {DateTime? ref}) =>
      (periodStart(payDay, ref: ref), periodEnd(payDay, ref: ref));

  static (DateTime, DateTime) periodOffset(int payDay, int offset,
      {DateTime? ref}) {
    final r = ref ?? DateTime.now();
    final targetMonth = DateTime(r.year, r.month + offset, 1);
    final shifted = _safeDay(targetMonth.year, targetMonth.month, r.day);
    return currentPeriod(payDay, ref: shifted);
  }

  static String formatArabic(DateTime d) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    // استخدام الأرقام الإنجليزية العادية لتجنب مشاكل الاتجاه
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String formatShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
