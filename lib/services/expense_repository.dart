import 'package:expense_tracker_app/models/category_record.dart';
import 'package:expense_tracker_app/models/dashboard_summary.dart';
import 'package:expense_tracker_app/models/expense_filter.dart';
import 'package:expense_tracker_app/models/transaction_record.dart';

abstract class ExpenseRepository {
  Future<List<TransactionRecord>> getTransactions({
    ExpenseFilter filter = const ExpenseFilter(),
    int? limit,
  });

  Future<DashboardSummary> getMonthlySummary(DateTime month);

  Future<List<CategoryRecord>> getCategories();

  Future<void> addTransaction(TransactionRecord transaction);

  Future<void> updateTransaction(TransactionRecord transaction);

  Future<void> deleteTransaction(String transactionId);
}
