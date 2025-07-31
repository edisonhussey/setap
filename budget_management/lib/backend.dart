import '../../../csv_service.dart';
import 'dart:async';
import '../../../models/continuous_function.dart';
import '../../../models/transaction.dart';

// Global balance variable that can be accessed from anywhere
int globalBalance = 0; 

class ManagementApp {
  List<ContinuousFunction> active_continuous = [];
  List<Transaction> active_transactions = [];

  Timer? _continuous_update_timer;
  

  int _update_interval_k = 10; // set to default check 10 second interval


  ManagementApp() {
    // Start the continuous update timer
    start_continuous_updates();
  }

  // global balance getter
  int get balance => globalBalance;
  
  // update global balace
  void update_balance(int delta) {
    globalBalance += delta;
  }
  

  void set_balance(int new_balance) {
    globalBalance = new_balance;
  }


  int get updateIntervalK => _update_interval_k;
  
  void setUpdateIntervalK(int interval_seconds) {
    _update_interval_k = interval_seconds;
    stop_continuous_updates();
    start_continuous_updates();
  }

  // Start the continuous update timer
  void start_continuous_updates() {
    if (_update_interval_k > 0) {
      _continuous_update_timer = Timer.periodic(
        Duration(seconds: _update_interval_k),
        (timer) => _process_continuous_functions(),
      );
    }
  }

  // stop the timer
  void stop_continuous_updates() {
    _continuous_update_timer?.cancel();
    _continuous_update_timer = null;
  }

  void _process_continuous_functions() {
    final current_epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    for (var function in active_continuous) {
      //time since last update
      int time_since_last_update = current_epoch - function.recent_update_seconds;
      if (time_since_last_update >= function.interval_seconds) {
        int cycles_elapsed = time_since_last_update ~/ function.interval_seconds;
        
        if (cycles_elapsed > 0) {
          int total_money_change = cycles_elapsed * function.balance_delta;
          
          // Update the global balance
          globalBalance += total_money_change;
          
          String transaction_name = '${function.function_name} (${cycles_elapsed} cycles)';
          Transaction continuous_transaction = Transaction(
            time: current_epoch,
            balance_delta: total_money_change,
            transaction_name: transaction_name,
          );
          active_transactions.add(continuous_transaction);
        
          function.recent_update_seconds += (cycles_elapsed * function.interval_seconds);
        
          print('Continuous Update: ${function.function_name} - ${cycles_elapsed} cycles, \$${total_money_change}');
        }
      }
    }
    
    update_continuous_function_db();
  }
  void trigger_continuous_update() {
    _process_continuous_functions();
  }

  void dispose() {
    stop_continuous_updates();
  }

  bool load_continuous_function_db(){
    return true;
  }

  bool update_continuous_function_db(){
    return true;
  }

  bool create_transaction_db(String name, int balance_delta) {
    return true;
  }

  bool load_transactions_db(int start, int end) {
    return true;
  }

  bool add_continuous_function(
    int init_time_epoch,
    int recent_update_seconds, //epoch- seconds
    int interval_seconds, //seconds
    String time_interval_name, // useful time format e.g. '12h5m' 
    String function_name, // the name of the function e.g. 'electricity bills'
    int balance_delta //effect on balance
  ){
    final current_epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    ContinuousFunction new_function = ContinuousFunction(
      init_time_epoch: init_time_epoch,
      recent_update_seconds: recent_update_seconds > 0 ? recent_update_seconds : current_epoch, // Use current time if not specified
      interval_seconds: interval_seconds,
      time_interval_name: time_interval_name,
      function_name: function_name,
      balance_delta: balance_delta,
    );
    
    active_continuous.add(new_function);
    update_continuous_function_db();
    
    print('Added continuous function: ${function_name} - \$${balance_delta} every ${interval_seconds}s');
    return true; //outcome of the function call
  }

  bool remove_continuous_function(String function_name){
    //remove from db and ds
    int initial_length = active_continuous.length;
    active_continuous.removeWhere((func) => func.function_name == function_name);
    bool removed = active_continuous.length < initial_length;
    
    if (removed) {
      update_continuous_function_db();
      print('Removed continuous function: ${function_name}');
    }
    return removed;
  }

  @deprecated
  bool update_recurring(){
    print('Warning: update_recurring() is deprecated. Continuous functions now update automatically every ${_update_interval_k} seconds.');
    _process_continuous_functions(); // Call the new method for backward compatibility
    return true;
  }

  bool create_transaction( 
      String name,
      int balance_delta,
      ) {
      final current_epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      Transaction cake = Transaction(time: current_epoch, balance_delta: balance_delta, transaction_name: name);
      active_transactions.add(cake);

      // Update the global balance
      globalBalance += balance_delta;

      create_transaction_db(name, balance_delta);
      return true;
    }

  Future<bool> export_transactions_to_csv({String file_name = 'transactions'}) async {
    try {
      final csv_data = CsvService.transactionsToCsv(active_transactions);
      return await CsvService.saveCsvFile(csv_data, file_name);
    } catch (e) {
      print('Error exporting transactions to CSV: $e');
      return false;
    }
  }

  Future<bool> import_transactions_from_csv() async {
    try {
      final csv_data = await CsvService.loadCsvFromFile();
      if (csv_data != null) {
        final imported_transaction_maps = CsvService.csvToTransactionMaps(csv_data);
        for (var transaction_map in imported_transaction_maps) {
          final transaction = Transaction(
            time: transaction_map['time'],
            balance_delta: transaction_map['balance_delta'],
            transaction_name: transaction_map['transaction_name'],
          );
          active_transactions.add(transaction);
          
          // Optionally update database with imported transaction
          create_transaction_db(transaction.transaction_name, transaction.balance_delta);
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error importing transactions from CSV: $e');
      return false;
    }
  }

  Future<bool> load_transactions_from_csv_path(String file_path) async {
    try {
      final csv_data = await CsvService.readCsvFile(file_path);
      final loaded_transaction_maps = CsvService.csvToTransactionMaps(csv_data);
      active_transactions.clear();
      
      for (var transaction_map in loaded_transaction_maps) {
        final transaction = Transaction(
          time: transaction_map['time'],
          balance_delta: transaction_map['balance_delta'],
          transaction_name: transaction_map['transaction_name'],
        );
        active_transactions.add(transaction);
      }
      
      return true;
    } catch (e) {
      print('Error loading transactions from CSV path: $e');
      return false;
    }
  }
}
