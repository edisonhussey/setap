class BalancePoint {
  final DateTime time;
  final double realistic;
  final double best_case;
  final double worst_case;
  final bool is_now;
  final bool is_future;

  BalancePoint({
    required this.time,
    required this.realistic,
    required this.best_case,
    required this.worst_case,
    required this.is_now,
    required this.is_future,
  });
}
