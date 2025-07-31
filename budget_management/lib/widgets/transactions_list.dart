import 'package:flutter/material.dart';
import '../../../../../models/transaction.dart';

class TransactionsList extends StatefulWidget {
  final List<Transaction> transactions;
  
  const TransactionsList({super.key, required this.transactions});

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
  bool _is_expanded = false;
  static const int _initial_display_count = 5;

  String _format_date_time(int epoch_seconds) {
    final date_time = DateTime.fromMillisecondsSinceEpoch(epoch_seconds * 1000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transaction_date = DateTime(date_time.year, date_time.month, date_time.day);
    
    if (transaction_date == today) {
      // Today - show only time
      return 'Today ${date_time.hour.toString().padLeft(2, '0')}:${date_time.minute.toString().padLeft(2, '0')}';
    } else if (transaction_date == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${date_time.hour.toString().padLeft(2, '0')}:${date_time.minute.toString().padLeft(2, '0')}';
    } else {
      // Older - show date and time
      return '${date_time.month}/${date_time.day} ${date_time.hour.toString().padLeft(2, '0')}:${date_time.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _build_transaction_item(Transaction transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.transaction_name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  _format_date_time(transaction.time),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '\$${transaction.balance_delta}',
            style: TextStyle(
              color: transaction.balance_delta >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const Text(
        'No transactions yet',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    // Reverse the list to show most recent first
    final reversed_transactions = widget.transactions.reversed.toList();
    final display_transactions = _is_expanded 
        ? reversed_transactions 
        : reversed_transactions.take(_initial_display_count).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display transactions
        ...display_transactions.map((transaction) => _build_transaction_item(transaction)),
        
        if (widget.transactions.length > _initial_display_count) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _is_expanded = !_is_expanded;
                });
              },
              icon: Icon(
                _is_expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(
                _is_expanded 
                    ? 'Show Less' 
                    : 'Show All (${widget.transactions.length - _initial_display_count} more)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
