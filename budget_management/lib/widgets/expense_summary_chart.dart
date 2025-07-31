import 'package:flutter/material.dart';
import '../../../../../models/expense_data.dart';
import '../../../../../backend.dart';
import 'pie_chart_painter.dart';

class ExpenseSummaryChart extends StatefulWidget {
  final ManagementApp management_app;
  
  const ExpenseSummaryChart({super.key, required this.management_app});

  @override
  State<ExpenseSummaryChart> createState() => _ExpenseSummaryChartState();
}

class _ExpenseSummaryChartState extends State<ExpenseSummaryChart> {
  String _selected_timeframe = '1 Week';
  
  final Map<String, int> _timeframe_days = {
    '1 Day': 1,
    '1 Week': 7,
    '1 Month': 30,
    '1 Year': 365,
  };

  // unique colours for segments
  final List<Color> _colors = [
    Colors.red.shade600,
    Colors.orange.shade600,
    Colors.purple.shade600,
    Colors.indigo.shade600,
    Colors.teal.shade600,
    Colors.brown.shade600,
    Colors.pink.shade600,
    Colors.deepOrange.shade600,
    Colors.cyan.shade600,
    Colors.amber.shade700,
  ];

  List<ExpenseData> _calculate_expenses(int days) {
    List<ExpenseData> expenses = [];
    
    // negative expense functions included only
    var expense_functions = widget.management_app.active_continuous
        .where((func) => func.balance_delta < 0)
        .toList();
    
    if (expense_functions.isEmpty) {
      return expenses; // Return empty list if no expenses
    }
    
    // Calculate total expense per timeframe for each function
    for (int i = 0; i < expense_functions.length; i++) {
      var func = expense_functions[i];
      
      // how much the function will cost over time
      double expense_per_second = func.balance_delta.abs() / func.interval_seconds;
      double total_expense_for_timeframe = expense_per_second * days * 86400; // 86400 seconds in a day
      
      expenses.add(ExpenseData(
        name: func.function_name,
        amount: total_expense_for_timeframe,
        color: _colors[i % _colors.length],
      ));
    }
    
    // largest first 
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    
    return expenses;
  }

  @override
  Widget build(BuildContext context) {
    int days = _timeframe_days[_selected_timeframe] ?? 7;
    List<ExpenseData> expense_data = _calculate_expenses(days);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expense Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selected_timeframe,
                      items: _timeframe_days.keys.map((String timeframe) {
                        return DropdownMenuItem<String>(
                          value: timeframe,
                          child: Text(timeframe, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? new_value) {
                        if (new_value != null) {
                          setState(() {
                            _selected_timeframe = new_value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (expense_data.isEmpty)
              // Show empty state when no expenses
              Container(
                height: 200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No Expense Functions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add some continuous functions with negative amounts to see expense breakdown',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              // Show pie chart and legend when expenses exist
              Column(
                children: [
                  // Pie Chart
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        // Pie Chart
                        Expanded(
                          flex: 3,
                          child: CustomPaint(
                            size: const Size(200, 200),
                            painter: PieChartPainter(expense_data),
                          ),
                        ),
                        
                        // Legend
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: expense_data.map((expense) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: expense.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '\$${expense.amount.toInt()}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Expenses in $_selected_timeframe',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${expense_data.fold(0.0, (sum, expense) => sum + expense.amount).toInt()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
