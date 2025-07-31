import 'package:flutter/material.dart';
import '../../../../../models/balance_point.dart';
import '../../../../../models/transaction_event.dart';
import '../../../../../backend.dart';
import 'balance_chart.dart';

class BalanceProjectionChart extends StatefulWidget {
  final ManagementApp management_app;
  
  const BalanceProjectionChart({super.key, required this.management_app});

  @override
  State<BalanceProjectionChart> createState() => _BalanceProjectionChartState();
}

class _BalanceProjectionChartState extends State<BalanceProjectionChart> {
  String _selected_timeframe = '1 Week';
  
  final Map<String, int> _timeframe_days = {
    '1 Day': 1,
    '1 Week': 7,
    '1 Month': 30,
    '1 Year': 365,
  };

  // future balance projections
  List<BalancePoint> _calculate_projection(int days) {
    List<BalancePoint> points = [];
    final now = DateTime.now();
    final end_time = now.add(Duration(days: days));
    
    if (widget.management_app.active_continuous.isEmpty) {
      // if there are no active functions just show as empty
      points.add(BalancePoint(
        time: now,
        realistic: globalBalance.toDouble(),
        best_case: globalBalance.toDouble(),
        worst_case: globalBalance.toDouble(),
        is_now: true,
        is_future: false,
      ));
      points.add(BalancePoint(
        time: end_time,
        realistic: globalBalance.toDouble(),
        best_case: globalBalance.toDouble(),
        worst_case: globalBalance.toDouble(),
        is_now: false,
        is_future: true,
      ));
      return points;
    }
    
    // To display where points start from
    points.add(BalancePoint(
      time: now,
      realistic: globalBalance.toDouble(),
      best_case: globalBalance.toDouble(),
      worst_case: globalBalance.toDouble(),
      is_now: true,
      is_future: false,
    ));
    
    // Generate transactions
    List<TransactionEvent> events = _generate_transaction_events(now, end_time);
    events.sort((a, b) => a.time.compareTo(b.time));
    
    // Simulate these
    double realistic_balance = globalBalance.toDouble();
    double best_balance = globalBalance.toDouble();
    double worst_balance = globalBalance.toDouble();
    
    for (var event in events) {
      // applies all transactions
      realistic_balance += event.amount;
      
      // Apply best case: income is 20% better, expenses are 10% less
      double best_amount = event.amount > 0 
          ? event.amount * 1.2  
          : event.amount * 0.9 ; 
      best_balance += best_amount;
      
      //similar for worst case
      double worst_amount = event.amount > 0 
          ? event.amount * 0.9  // 10% less income
          : event.amount * 1.2; // 20% more expense

      worst_balance += worst_amount;
      
      points.add(BalancePoint(
        time: event.time,
        realistic: realistic_balance,
        best_case: best_balance,
        worst_case: worst_balance,
        is_now: false,
        is_future: true,
      ));
    }
    
    return points;
  }
  
  // Generate all transaction events within the timeframe
  List<TransactionEvent> _generate_transaction_events(DateTime start_time, DateTime end_time) {
    List<TransactionEvent> events = [];
    
    for (var func in widget.management_app.active_continuous) {
      DateTime next_transaction_time = start_time.add(Duration(seconds: func.interval_seconds));
      
      while (next_transaction_time.isBefore(end_time)) {
        events.add(TransactionEvent(
          time: next_transaction_time,
          amount: func.balance_delta.toDouble(),
          function_name: func.function_name,
        ));
        
        next_transaction_time = next_transaction_time.add(Duration(seconds: func.interval_seconds));
      }
    }
    
    return events;
  }

  @override
  Widget build(BuildContext context) {
    int days = _timeframe_days[_selected_timeframe] ?? 7;
    List<BalancePoint> projection_data = _calculate_projection(days);
    
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
                  'Balance Projection',
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
            
            // the chart
            SizedBox(
              height: 220, // increased height to accommodate labels
              child: BalanceChart(points: projection_data, timeframe_days: days),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _build_legend_item('Realistic', Colors.blue, Icons.trending_up),
                _build_legend_item('Best Case', Colors.green, Icons.trending_up),
                _build_legend_item('Worst Case', Colors.red, Icons.trending_down),
                _build_legend_item('Now', Colors.orange, Icons.radio_button_checked),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Projection Summary
            _build_projection_summary(projection_data, days),
          ],
        ),
      ),
    );
  }

  Widget _build_legend_item(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _build_projection_summary(List<BalancePoint> points, int days) {
    if (points.isEmpty) return const SizedBox.shrink();
    
    BalancePoint future_point = points.lastWhere((p) => p.is_future, orElse: () => points.last);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),


      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projection in $_selected_timeframe',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              _build_summary_item('Realistic', future_point.realistic, Colors.blue),
              _build_summary_item('Best Case', future_point.best_case, Colors.green),

              _build_summary_item('Worst Case', future_point.worst_case, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build_summary_item(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
        Text(
          '\$${value.toInt()}',
          style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
