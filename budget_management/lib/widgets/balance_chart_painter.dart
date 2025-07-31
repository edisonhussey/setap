import 'package:flutter/material.dart';
import '../../../../../models/balance_point.dart';

class BalanceChartPainter extends CustomPainter {
  final List<BalancePoint> points;
  final int timeframe_days;

  BalanceChartPainter(this.points, this.timeframe_days);

  String _get_time_label(int index, int total_points) {
    double progress = index / total_points;
    double days_from_now = progress * timeframe_days;
    
    if (timeframe_days <= 1) {
      // for 1 day: show hours (6h, 12h, 18h, 24h)
      int hours = (days_from_now * 24).round();
      return '${hours}h';
    } else if (timeframe_days <= 7) {
      // For 1 week: show days 
      int days = days_from_now.round();
      return days == 0 ? 'Now' : '${days}d';
    } else if (timeframe_days <= 30) {
      // For 1 month: show weeks (1w, 2w, 3w, 4w)
      int weeks = (days_from_now / 7).round();
      return weeks == 0 ? 'Now' : '${weeks}w';
    } else {
      // for 1 year: show monthes (1m, 2m, 3m, etc.)
      int months = (days_from_now / 30).round();
      return months == 0 ? 'Now' : '${months}m';
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // reserve space for labels
    const double bottom_padding = 25.0;
    const double right_padding = 40.0;
    const double left_padding = 10.0;
    const double top_padding = 10.0;
    
    final chart_width = size.width - left_padding - right_padding;
    final chart_height = size.height - top_padding - bottom_padding;

    final paint = Paint()..strokeWidth = 2..style = PaintingStyle.stroke;
    final fill_paint = Paint()..style = PaintingStyle.fill;
    final text_painter = TextPainter(textDirection: TextDirection.ltr);

    // find min and max values for scaling
    double min_value = points.fold(double.infinity, (min, point) => 
        [min, point.realistic, point.best_case, point.worst_case].reduce((a, b) => a < b ? a : b));
    double max_value = points.fold(double.negativeInfinity, (max, point) => 
        [max, point.realistic, point.best_case, point.worst_case].reduce((a, b) => a > b ? a : b));

    // adds some padding to the range
    double range = max_value - min_value;
    if (range == 0) range = 100; // prevent division by zero
    min_value -= range * 0.1;
    max_value += range * 0.1;
    range = max_value - min_value;

    // Helper function to convert values to screen coordinates
    Offset get_point(int index, double value) {
      double x = left_padding + (index / (points.length - 1)) * chart_width;
      double y = top_padding + chart_height - ((value - min_value) / range) * chart_height;
      return Offset(x, y);
    }

    // Draw best case area (light green fill) with step-wise pattern
    Path best_case_path = Path();
    best_case_path.moveTo(left_padding, top_padding + chart_height);
    for (int i = 0; i < points.length; i++) {
      Offset point = get_point(i, points[i].best_case);
      if (i == 0) {
        best_case_path.lineTo(point.dx, point.dy);
      } else {
        Offset prev_point = get_point(i - 1, points[i - 1].best_case);
        best_case_path.lineTo(point.dx, prev_point.dy);
        best_case_path.lineTo(point.dx, point.dy);
      }
    }
    best_case_path.lineTo(left_padding + chart_width, top_padding + chart_height);
    best_case_path.close();
    fill_paint.color = Colors.green.withOpacity(0.1);
    canvas.drawPath(best_case_path, fill_paint);

    // draw worst case area with step-wise pattern
    Path worst_case_path = Path();
    worst_case_path.moveTo(left_padding, top_padding + chart_height);
    for (int i = 0; i < points.length; i++) {
      Offset point = get_point(i, points[i].worst_case);
      if (i == 0) {
        worst_case_path.lineTo(point.dx, point.dy);
      } else {
        Offset prev_point = get_point(i - 1, points[i - 1].worst_case);
        // Horizontal then vertical for step pattern
        worst_case_path.lineTo(point.dx, prev_point.dy);
        worst_case_path.lineTo(point.dx, point.dy);
      }
    }
    worst_case_path.lineTo(left_padding + chart_width, top_padding + chart_height);
    worst_case_path.close();
    fill_paint.color = Colors.red.withOpacity(0.1);
    canvas.drawPath(worst_case_path, fill_paint);

    // Draw the lines with step-wise (blocky) appearence for discrete transactions
    Path realistic_path = Path();
    Path best_path = Path();
    Path worst_path = Path();

    for (int i = 0; i < points.length; i++) {
      Offset realistic_point = get_point(i, points[i].realistic);
      Offset best_point = get_point(i, points[i].best_case);
      Offset worst_point = get_point(i, points[i].worst_case);

      if (i == 0) {
        realistic_path.moveTo(realistic_point.dx, realistic_point.dy);
        best_path.moveTo(best_point.dx, best_point.dy);
        worst_path.moveTo(worst_point.dx, worst_point.dy);
      } else {
        // create step-wise lines: horizontal then vertical for blocky appearance
        Offset prev_realistic_point = get_point(i - 1, points[i - 1].realistic);
        Offset prev_best_point = get_point(i - 1, points[i - 1].best_case);
        Offset prev_worst_point = get_point(i - 1, points[i - 1].worst_case);
        
        realistic_path.lineTo(realistic_point.dx, prev_realistic_point.dy);
        best_path.lineTo(best_point.dx, prev_best_point.dy);
        worst_path.lineTo(worst_point.dx, prev_worst_point.dy);
        
        // Then draw vertical line to current y-position
        realistic_path.lineTo(realistic_point.dx, realistic_point.dy);
        best_path.lineTo(best_point.dx, best_point.dy);
        worst_path.lineTo(worst_point.dx, worst_point.dy);
      }
    }

    paint.color = Colors.blue;
    paint.strokeWidth = 3;
    canvas.drawPath(realistic_path, paint);



    paint.color = Colors.green;
    paint.strokeWidth = 2;
    canvas.drawPath(best_path, paint);


    paint.color = Colors.red;
    paint.strokeWidth = 2;
    canvas.drawPath(worst_path, paint);

    // draw small dots at transaction points (except the "now" point)
    for (int i = 1; i < points.length; i++) {
      if (points[i].is_future) {
        Offset realistic_point = get_point(i, points[i].realistic);
        
        // Draw small dot to indicate transaction moment
        fill_paint.color = Colors.blue.shade800;
        canvas.drawCircle(realistic_point, 3, fill_paint);
        
        fill_paint.color = Colors.white;
        canvas.drawCircle(realistic_point, 1.5, fill_paint);
      }
    }

    // Draw "now" marker (first point)
    if (points.isNotEmpty) {
      Offset now_point = get_point(0, points[0].realistic);
      
      paint.color = Colors.orange;
      paint.strokeWidth = 2;
      canvas.drawLine(
        Offset(now_point.dx, top_padding),
        Offset(now_point.dx, top_padding + chart_height),
        paint,
      );

      // Draw "now" point
      fill_paint.color = Colors.orange;
      canvas.drawCircle(now_point, 6, fill_paint);
      
      fill_paint.color = Colors.white;
      canvas.drawCircle(now_point, 3, fill_paint);
    }

    // draw zero line if it's in the visible range
    if (min_value <= 0 && max_value >= 0) {
      double zero_y = top_padding + chart_height - ((0 - min_value) / range) * chart_height;
      paint.color = Colors.grey.shade400;
      paint.strokeWidth = 1;
      canvas.drawLine(Offset(left_padding, zero_y), Offset(left_padding + chart_width, zero_y), paint);
    }

    // draw bottom axis labels (time)
    const int num_time_labels = 5;
    for (int i = 0; i < num_time_labels; i++) {
      double progress = i / (num_time_labels - 1);
      double x = left_padding + progress * chart_width;
      int point_index = (progress * (points.length - 1)).round();
      
      String label = _get_time_label(point_index, points.length - 1);
      
      text_painter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      text_painter.layout();
      
      // the text centering
      double text_x = x - text_painter.width / 2;
      double text_y = size.height - bottom_padding + 5;
      
      text_painter.paint(canvas, Offset(text_x, text_y));
    }

    // right axis labels
    const int num_value_labels = 4;
    for (int i = 0; i < num_value_labels; i++) {
      double progress = i / (num_value_labels - 1);
      double value = min_value + (max_value - min_value) * (1 - progress);
      double y = top_padding + progress * chart_height;
      
      String label = '\$${value.round()}';
      
      text_painter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
      text_painter.layout();
      
      double text_x = size.width - right_padding + 5;
      double text_y = y - text_painter.height / 2;
      
      text_painter.paint(canvas, Offset(text_x, text_y));
    }
  }

  @override
  bool shouldRepaint(BalanceChartPainter old_delegate) {
    return points != old_delegate.points || timeframe_days != old_delegate.timeframe_days;
  }
}
