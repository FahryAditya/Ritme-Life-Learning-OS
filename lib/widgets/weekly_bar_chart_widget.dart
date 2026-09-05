import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom Painter untuk Bar Chart mingguan sesi fokus
class WeeklyBarChartPainter extends CustomPainter {
  final List<int> minutesPerDay; // 7 values, Mon–Sun
  final int todayIndex; // 0=Mon..6=Sun
  final double animationValue;

  static const List<String> dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  WeeklyBarChartPainter({
    required this.minutesPerDay,
    required this.todayIndex,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxMinutes = minutesPerDay.reduce(math.max).toDouble();
    final maxVal = maxMinutes < 1 ? 30.0 : maxMinutes;

    const labelHeight = 20.0;
    const topPadding = 24.0;
    final barAreaHeight = size.height - labelHeight - topPadding;
    final barWidth = (size.width / 7) * 0.45;
    final slotWidth = size.width / 7;

    for (int i = 0; i < 7; i++) {
      final minutes = minutesPerDay[i];
      final barH = (minutes / maxVal) * barAreaHeight * animationValue;
      final isToday = i == todayIndex;

      final x = slotWidth * i + slotWidth / 2;
      final barLeft = x - barWidth / 2;
      final barTop = topPadding + barAreaHeight - barH;

      // Draw bar
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth, math.max(barH, 0)),
        const Radius.circular(6),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isToday
              ? [const Color(0xFF6C4CE0), const Color(0xFF987CFE)]
              : [
                  AppColors.primaryFixed,
                  AppColors.primaryFixed.withValues(alpha: 0.6),
                ],
        ).createShader(Rect.fromLTWH(barLeft, barTop, barWidth, barH));

      if (barH > 0) {
        canvas.drawRRect(rrect, paint);

        // Value label on top of bar
        if (minutes > 0 && animationValue > 0.8) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${minutes}m',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isToday ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(
            canvas,
            Offset(x - textPainter.width / 2, barTop - 16),
          );
        }
      }

      // Today indicator dot
      if (isToday) {
        final dotPaint = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(x, topPadding + barAreaHeight + labelHeight - 6),
          3,
          dotPaint,
        );
      }

      // Day label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: dayLabels[i],
          style: TextStyle(
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, topPadding + barAreaHeight + 4),
      );
    }

    // Baseline
    final basePaint = Paint()
      ..color = AppColors.outlineVariant
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, topPadding + barAreaHeight),
      Offset(size.width, topPadding + barAreaHeight),
      basePaint,
    );
  }

  @override
  bool shouldRepaint(WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.minutesPerDay != minutesPerDay;
  }
}

/// Widget Bar Chart mingguan dengan animasi grow-up
class WeeklyBarChartWidget extends StatefulWidget {
  final List<int> minutesPerDay; // 7 values Mon–Sun
  final int todayIndex;

  const WeeklyBarChartWidget({
    super.key,
    required this.minutesPerDay,
    required this.todayIndex,
  });

  @override
  State<WeeklyBarChartWidget> createState() => _WeeklyBarChartWidgetState();
}

class _WeeklyBarChartWidgetState extends State<WeeklyBarChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(WeeklyBarChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minutesPerDay != widget.minutesPerDay) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(double.infinity, 130),
          painter: WeeklyBarChartPainter(
            minutesPerDay: widget.minutesPerDay,
            todayIndex: widget.todayIndex,
            animationValue: _animation.value,
          ),
        );
      },
    );
  }
}
