class TransactionEvent {
  final DateTime time;
  final double amount;
  final String function_name;

  TransactionEvent({
    required this.time,
    required this.amount,
    required this.function_name,
  });
}
