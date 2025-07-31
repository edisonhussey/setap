import 'package:flutter/material.dart';
import '../../../../../models/expense_data.dart';

class PieChartPainter extends CustomPainter {
  final List<ExpenseData> expenses;

  PieChartPainter(this.expenses);

  @override
  void paint(Canvas canvas, Size size) {
    if (expenses.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 20;
    
    // calculates the total amount
    double total_amount = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    
    if (total_amount == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    
    double start_angle = -90 * (3.14159 / 180); // Start from top (-90 degrees)
    
    for (var expense in expenses) {
      double sweep_angle = (expense.amount / total_amount) * 2 * 3.14159;
      
      paint.color = expense.color;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start_angle,
        sweep_angle,
        true,
        paint,
      );
      
      start_angle += sweep_angle;
    }
    
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.4, paint);
    
    // todraw border around the pie chart
    paint.color = Colors.grey.shade300;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(PieChartPainter old_delegate) {
    return expenses != old_delegate.expenses;
  }
}
