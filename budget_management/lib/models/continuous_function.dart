class ContinuousFunction {
  int init_time_epoch = 0;
  int recent_update_seconds = 0; // epoch - seconds
  int interval_seconds = 0; // seconds

  String time_interval_name = ''; // useful time format e.g. '12h5m' 
  String function_name = ''; // the name of the function e.g. 'electricity bills'

  int balance_delta = 0; // effect on balance

  ContinuousFunction({
    required this.init_time_epoch,
    required this.recent_update_seconds,
    required this.interval_seconds,
    required this.time_interval_name,
    required this.function_name,
    required this.balance_delta,
  });
}
