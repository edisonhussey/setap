import 'package:flutter/material.dart';
import '../../../../../models/balance_point.dart';
import 'balance_chart_painter.dart';

class BalanceChart extends StatelessWidget {
  final List<BalancePoint> points;
  final int timeframe_days;

  const BalanceChart({super.key, required this.points, required this.timeframe_days});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: Colors.grey)),
      );
    }

    return CustomPaint(
      size: Size.infinite,
      painter: BalanceChartPainter(points, timeframe_days),
    );
  }
}
