import 'package:flutter/material.dart';
import 'dart:async';
import '../../../backend.dart';
import '../../../widgets/balance_projection_chart.dart';
import '../../../widgets/expense_summary_chart.dart';
import '../../../widgets/transactions_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Balance Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ManagementApp management_app;
  
  // Controllers for form inputs
  final TextEditingController _function_name_controller = TextEditingController();
  final TextEditingController _function_amount_controller = TextEditingController();
  final TextEditingController _function_interval_controller = TextEditingController();
  final TextEditingController _transaction_name_controller = TextEditingController();
  final TextEditingController _transaction_amount_controller = TextEditingController();
  final TextEditingController _interval_controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    management_app = ManagementApp();
    
    _interval_controller.text = management_app.updateIntervalK.toString();
    
    _start_ui_update_timer();
  }

  void _start_ui_update_timer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger UI rebuild to show updated balance
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    management_app.dispose();
    _function_name_controller.dispose();
    _function_amount_controller.dispose();
    _function_interval_controller.dispose();
    _transaction_name_controller.dispose();
    _transaction_amount_controller.dispose();
    _interval_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Balance Manager'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Projection Chart
            BalanceProjectionChart(management_app: management_app),
            
            const SizedBox(height: 16),
            
            // Expense Summary Pie Chart
            ExpenseSummaryChart(management_app: management_app),
            
            const SizedBox(height: 16),
            
            // Balance Display Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${globalBalance}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: globalBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // System Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Active Functions: ${management_app.active_continuous.length}'),
                        Text('Transactions: ${management_app.active_transactions.length}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Update Interval Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Interval (seconds)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _interval_controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter seconds',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            int? new_interval = int.tryParse(_interval_controller.text);
                            if (new_interval != null && new_interval > 0) {
                              management_app.setUpdateIntervalK(new_interval);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update interval set to ${new_interval}s')),
                              );
                            }
                          },
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Add Continuous Function Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Continuous Function',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _function_name_controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Function Name',
                        hintText: 'e.g., Salary, Rent, Bills',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _function_amount_controller,
                            keyboardType: TextInputType.numberWithOptions(signed: true),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Amount (\$)',
                              hintText: '+100 or -50',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _function_interval_controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Interval (sec)',
                              hintText: '60',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          String name = _function_name_controller.text.trim();
                          int? amount = int.tryParse(_function_amount_controller.text.trim());
                          int? interval = int.tryParse(_function_interval_controller.text.trim());
                          
                          if (name.isNotEmpty && amount != null && interval != null && interval > 0) {
                            String interval_name = '${interval}s';
                            management_app.add_continuous_function(
                              DateTime.now().millisecondsSinceEpoch ~/ 1000,
                              0,
                              interval,
                              interval_name,
                              name,
                              amount,
                            );
                            
                            // Clear form
                            _function_name_controller.clear();
                            _function_amount_controller.clear();
                            _function_interval_controller.clear();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added continuous function: $name')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all fields correctly')),
                            );
                          }
                        },
                        child: const Text('Add Continuous Function'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Add One-off Transaction Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add One-off Transaction',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _transaction_name_controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Transaction Name',
                        hintText: 'e.g., Groceries, Bonus, Coffee',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _transaction_amount_controller,
                      keyboardType: TextInputType.numberWithOptions(signed: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Amount (\$)',
                        hintText: '+500 or -25',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          String name = _transaction_name_controller.text.trim();
                          int? amount = int.tryParse(_transaction_amount_controller.text.trim());
                          
                          if (name.isNotEmpty && amount != null) {
                            management_app.create_transaction(name, amount);
                            
                            // Clear form
                            _transaction_name_controller.clear();
                            _transaction_amount_controller.clear();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added transaction: $name (\$${amount})')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all fields correctly')),
                            );
                          }
                        },
                        child: const Text('Add Transaction'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Active Continuous Functions List
            if (management_app.active_continuous.isNotEmpty) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Continuous Functions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...management_app.active_continuous.map((func) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    func.function_name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '\$${func.balance_delta} every ${func.time_interval_name}',
                                    style: TextStyle(
                                      color: func.balance_delta >= 0 ? Colors.green : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                management_app.remove_continuous_function(func.function_name);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Removed: ${func.function_name}')),
                                );
                              },
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Recent Transactions List
            if (management_app.active_transactions.isNotEmpty) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Transactions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${management_app.active_transactions.length} total',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TransactionsList(transactions: management_app.active_transactions),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
