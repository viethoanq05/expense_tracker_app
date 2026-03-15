import 'dart:io';

import 'package:csv/csv.dart';
import 'package:expense_tracker_app/services/expense_repository.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  ExportService(this._repository);

  final ExpenseRepository _repository;

  Future<Directory> getExportDirectory() async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    final exportDirectory = Directory(
      '${base.path}${Platform.pathSeparator}exports',
    );
    await exportDirectory.create(recursive: true);
    return exportDirectory;
  }

  Future<File> exportTransactionsToCsv({bool excelCompatible = false}) async {
    final transactions = await _repository.getTransactions();
    final rows = <List<dynamic>>[
      ['ID', 'Title', 'Amount', 'Date', 'Category', 'Type', 'Note'],
      ...transactions.map(
        (transaction) => [
          transaction.id,
          transaction.title,
          transaction.amount.toStringAsFixed(0),
          transaction.date.toIso8601String(),
          transaction.category,
          transaction.type.name,
          transaction.note ?? '',
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final content = excelCompatible ? '\ufeff$csv' : csv;
    final exportDirectory = await getExportDirectory();

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final suffix = excelCompatible ? 'excel' : 'csv';
    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}transactions_${timestamp}_$suffix.csv',
    );

    return file.writeAsString(content);
  }
}
