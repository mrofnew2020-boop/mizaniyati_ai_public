import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class BalanceRing extends StatelessWidget {
  final double income;
  final double expense;
  final double size;

  const BalanceRing({
    super.key, required this.income, required this.expense, this.size = 260,
  });

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    final percent = income > 0 ? ((expense / income) * 100).toStringAsFixed(0) : '0';

    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              income: income,
              expense: expense,
              stroke: 18, // تصغير سمك الخط قليلاً لتبدو أكثر دقة مع التوهج
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('الصافي',
                style: TextStyle(color: AppColors.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatShort(net),
                style: TextStyle(
                  color: net < 0 ? AppColors.danger : Colors.white,
                  fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
                child: Text('$percent% من الدخل',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: AppColors.primaryPink,
                    fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double income;
  final double expense;
  final double stroke;

  _RingPainter({
    required this.income,
    required this.expense,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. رسم الدائرة الخلفية الرمادية
    final bgPaint = Paint()
      ..color = AppColors.cardElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bgPaint);

    if (income <= 0) return;

    final expenseRatio = (expense / income).clamp(0.0, 1.0);
    final remainingRatio = 1.0 - expenseRatio;
    
    // زوايا الرسم (تبدأ من أعلى الحلقة)
    const startAngle = -math.pi / 2;
    final blueSweep = remainingRatio * 2 * math.pi;
    final pinkSweep = expenseRatio * 2 * math.pi;

    // --- رسم القوس الأزرق (المتبقي) ---
    if (blueSweep > 0) {
      // طبقة التوهج
      final blueGlowPaint = Paint()
        ..color = AppColors.primaryBlue.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawArc(rect, startAngle, blueSweep, false, blueGlowPaint);

      // الطبقة الواضحة
      final bluePaint = Paint()
        ..color = AppColors.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, blueSweep, false, bluePaint);
    }

    // --- رسم القوس الزهري (المصروفات) ---
    if (pinkSweep > 0) {
      final pinkColor = expense > income ? AppColors.danger : AppColors.primaryPink;
      final pinkStartAngle = startAngle + blueSweep;

      // طبقة التوهج
      final pinkGlowPaint = Paint()
        ..color = pinkColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawArc(rect, pinkStartAngle, pinkSweep, false, pinkGlowPaint);

      // الطبقة الواضحة
      final pinkPaint = Paint()
        ..color = pinkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, pinkStartAngle, pinkSweep, false, pinkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.income != income ||
      oldDelegate.expense != expense ||
      oldDelegate.stroke != stroke;
}
