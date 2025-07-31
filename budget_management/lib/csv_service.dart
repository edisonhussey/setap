import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class CsvService {
  
  static Future<List<List<dynamic>>?> loadCsvFromFile() async {
    try {
      // Open file picker dialog
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        return await readCsvFile(filePath);
      }
      return null;
    } catch (e) {
      print('Error loading CSV file: $e');
      return null;
    }
  }

  static Future<List<List<dynamic>>> readCsvFile(String filePath) async {
    final file = File(filePath);
    final contents = await file.readAsString();
    
    // Parse CSV content
    const csvConverter = CsvToListConverter();
    return csvConverter.convert(contents);
  }

  static Future<bool> saveCsvFile(List<List<dynamic>> data, String fileName) async {
    try {
      // Gets the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.csv';
      
      // Converts data to CSV format
      const listToCsvConverter = ListToCsvConverter();
      String csvContent = listToCsvConverter.convert(data);
      
      final file = File(filePath);
      await file.writeAsString(csvContent);
      
      print('CSV file saved to: $filePath');
      return true;
    } catch (e) {
      print('Error saving CSV file: $e');
      return false;
    }
  }

  static Future<List<List<dynamic>>> loadCsvFromAssets(String assetPath) async {
    try {

      final data = await DefaultAssetBundle.of(navigatorKey.currentContext!)
          .loadString(assetPath);
      
      const csvConverter = CsvToListConverter();
      return csvConverter.convert(data);
    } catch (e) {
      print('Error loading CSV from assets: $e');
      return [];
    }
  }

  static List<List<dynamic>> createSampleData() {
    return [
      ['Name', 'Age', 'City'],
      ['John Doe', 25, 'New York'],
      ['Jane Smith', 30, 'Los Angeles'],
      ['Bob Johnson', 35, 'Chicago'],
    ];
  }

  static List<List<dynamic>> transactionsToCsv<T>(List<T> transactions) {
    List<List<dynamic>> csvData = [
      ['Time (Epoch)', 'Balance Delta', 'Transaction Name', 'Date']
    ];

    for (var transaction in transactions) {
      // piecewise transaction translation
      csvData.add([
        (transaction as dynamic).time,
        (transaction as dynamic).balance_delta,

        (transaction as dynamic).transaction_name,
        DateTime.fromMillisecondsSinceEpoch((transaction as dynamic).time * 1000).toString(),
      ]);
    }

    return csvData;
  }

  static List<Map<String, dynamic>> csvToTransactionMaps(List<List<dynamic>> csvData) {
    List<Map<String, dynamic>> transactions = [];
    
    for (int i = 1; i < csvData.length; i++) {
      var row = csvData[i];
        if (row.length >= 3) {
          transactions.add({
            'time': int.tryParse(row[0].toString()) ?? 0,
            'balance_delta': int.tryParse(row[1].toString()) ?? 0,
            'transaction_name': row[2].toString(),
          });
        }
    }
    
    return transactions;
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
