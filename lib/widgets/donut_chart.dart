import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class DonutChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double totalAmount;

  const DonutChart({
    super.key,
    required this.categoryTotals,
    required this.totalAmount,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryTotals != widget.categoryTotals ||
        oldWidget.totalAmount != widget.totalAmount) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalAmount <= 0 || widget.categoryTotals.isEmpty) {
      return Center(
        child: Container(
          height: 180,
          alignment: Alignment.center,
          child: Text(
            'Chưa có dữ liệu chi tiêu',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  categoryTotals: widget.categoryTotals,
                  totalAmount: widget.totalAmount,
                  progress: _animation.value,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Tổng cộng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            AppConstants.formatCurrency(widget.totalAmount),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: widget.categoryTotals.entries.map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final percentage = (amount / widget.totalAmount * 100).toStringAsFixed(1);
                final color = AppConstants.categoryColors[category] ?? Colors.grey;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$category ($percentage%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;
  final double totalAmount;
  final double progress;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.categoryTotals,
    required this.totalAmount,
    required this.progress,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 12;
    const strokeWidth = 24.0;

    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (totalAmount <= 0) return;

    double startAngle = -pi / 2;

    for (final entry in categoryTotals.entries) {
      final category = entry.key;
      final amount = entry.value;
      final sweepAngle = (amount / totalAmount) * 2 * pi * progress;

      final color = AppConstants.categoryColors[category] ?? Colors.grey;
      final slicePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        slicePaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.categoryTotals != categoryTotals;
  }
}
