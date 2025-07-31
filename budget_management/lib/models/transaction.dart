class Transaction {
  int time = 0;
  int balance_delta = 0;
  String transaction_name = "";

  Transaction({
    required this.time,
    required this.balance_delta,
    required this.transaction_name
  });
}
