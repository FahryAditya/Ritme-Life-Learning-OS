import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Data untuk satu irisan donut chart
class DonutSlice {
  final String label;
  final double value;
  final Color color;

  DonutSlice({required this.label, required this.value, required this.color});
}

/// Custom Painter untuk Donut Chart interaktif
class DonutChartPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final double animationValue; // 0.0 – 1.0
  final int? selectedIndex;
  final double total;

  static const List<Color> defaultPalette = [
    Color(0xFF6C4CE0),
    Color(0xFF987CFE),
    Color(0xFF534978),
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFFFF5722),
    Color(0xFFFFC107),
  ];

  DonutChartPainter({
    required this.slices,
    required this.animationValue,
    this.selectedIndex,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty || total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 8;
    const innerRadius = 0.52; // donut ratio

    double startAngle = -math.pi / 2;
    final maxAngle = 2 * math.pi * animationValue;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweepAngle = (slice.value / total) * 2 * math.pi;
      final clampedSweep = math.min(sweepAngle, maxAngle - (startAngle + math.pi / 2));
      if (clampedSweep <= 0) break;

      final isSelected = selectedIndex == i;
      final radius = isSelected ? outerRadius + 6 : outerRadius;
      final innerR = radius * innerRadius;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;

      // Shadow for selected
      if (isSelected) {
        final shadowPaint = Paint()
          ..color = slice.color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        final rect = Rect.fromCircle(center: center, radius: radius + 4);
        canvas.drawArc(rect, startAngle, clampedSweep, true, shadowPaint);
      }

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, startAngle, clampedSweep, true, paint);

      // Cut inner circle (donut hole)
      final holePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, innerR, holePaint);

      startAngle += sweepAngle;
      if (startAngle - (-math.pi / 2) >= maxAngle) break;
    }

    // Thin divider lines between slices
    if (animationValue >= 1.0 && slices.length > 1) {
      double divStart = -math.pi / 2;
      final divPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < slices.length; i++) {
        final sweep = (slices[i].value / total) * 2 * math.pi;
        final dx = center.dx + outerRadius * math.cos(divStart);
        final dy = center.dy + outerRadius * math.sin(divStart);
        canvas.drawLine(center, Offset(dx, dy), divPaint);
        divStart += sweep;
      }
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.slices.length != slices.length;
  }
}

/// Widget Donut Chart lengkap dengan animasi, legenda, dan tap detection
class DonutChartWidget extends StatefulWidget {
  final Map<String, double> categoryData;
  final double total;

  const DonutChartWidget({
    super.key,
    required this.categoryData,
    required this.total,
  });

  @override
  State<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<DonutChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;
  List<DonutSlice> _slices = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _buildSlices();
    _controller.forward();
  }

  @override
  void didUpdateWidget(DonutChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryData != widget.categoryData) {
      _buildSlices();
      _controller.forward(from: 0);
    }
  }

  void _buildSlices() {
    final keys = widget.categoryData.keys.toList();
    _slices = List.generate(keys.length, (i) {
      return DonutSlice(
        label: keys[i],
        value: widget.categoryData[keys[i]]!,
        color: DonutChartPainter.defaultPalette[i % DonutChartPainter.defaultPalette.length],
      );
    });
  }

  String _formatRupiah(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i > 0) buf.write('.');
    }
    return buf.toString().split('').reversed.join('');
  }

  void _onTapDown(TapDownDetails details, Size size) {
    if (_slices.isEmpty || widget.total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final tap = details.localPosition;
    final dx = tap.dx - center.dx;
    final dy = tap.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final outerRadius = math.min(size.width, size.height) / 2 - 8;
    final innerRadius = outerRadius * 0.52;

    if (distance < innerRadius || distance > outerRadius + 10) {
      setState(() => _selectedIndex = null);
      return;
    }

    double angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    double cumAngle = 0;
    for (int i = 0; i < _slices.length; i++) {
      final sweep = (_slices[i].value / widget.total) * 2 * math.pi;
      cumAngle += sweep;
      if (angle <= cumAngle) {
        setState(() => _selectedIndex = _selectedIndex == i ? null : i);
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slices.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Belum ada data pengeluaran',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, 200);
            return GestureDetector(
              onTapDown: (d) => _onTapDown(d, size),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    painter: DonutChartPainter(
                      slices: _slices,
                      animationValue: _animation.value,
                      selectedIndex: _selectedIndex,
                      total: widget.total,
                    ),
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedIndex != null
                                  ? _slices[_selectedIndex!].label
                                  : 'Total',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${_formatRupiah(_selectedIndex != null ? _slices[_selectedIndex!].value : widget.total)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _selectedIndex != null
                                    ? _slices[_selectedIndex!].color
                                    : AppColors.onSurface,
                              ),
                            ),
                            if (_selectedIndex != null)
                              Text(
                                '${(_slices[_selectedIndex!].value / widget.total * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _slices[_selectedIndex!].color,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: List.generate(_slices.length, (i) {
            final s = _slices[i];
            final pct = (s.value / widget.total * 100).toStringAsFixed(1);
            final isSelected = _selectedIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = isSelected ? null : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? s.color.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? s.color : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${s.label} $pct%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? s.color : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
