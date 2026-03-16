import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
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

  Future<File> exportTransactionsToCsv() async {
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
    final content = csv;
    final exportDirectory = await getExportDirectory();

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}transactions_$timestamp.csv',
    );

    return file.writeAsString(content);
  }

  Future<File> exportTransactionsToExcel() async {
    final transactions = await _repository.getTransactions();
    final workbook = Excel.createExcel();
    const sheetName = 'Transactions';
    final sheet = workbook[sheetName];

    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Title'),
      TextCellValue('Amount'),
      TextCellValue('Date'),
      TextCellValue('Category'),
      TextCellValue('Type'),
      TextCellValue('Note'),
    ]);

    for (final transaction in transactions) {
      sheet.appendRow([
        TextCellValue(transaction.id),
        TextCellValue(transaction.title),
        DoubleCellValue(transaction.amount),
        TextCellValue(transaction.date.toIso8601String()),
        TextCellValue(transaction.category),
        TextCellValue(transaction.type.name),
        TextCellValue(transaction.note ?? ''),
      ]);
    }

    final bytes = workbook.encode();
    if (bytes == null) {
      throw StateError('Failed to generate Excel file.');
    }

    final exportDirectory = await getExportDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}transactions_$timestamp.xlsx',
    );

    return file.writeAsBytes(bytes, flush: true);
  }
}
