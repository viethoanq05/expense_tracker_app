import 'package:expense_tracker_app/models/dashboard_summary.dart';
import 'package:expense_tracker_app/models/expense_filter.dart';
import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/services/expense_repository.dart';

class DashboardDataController {
  DashboardDataController(this._repository);

  final ExpenseRepository _repository;

  Future<DashboardSummary> getMonthlySummary(DateTime month) {
    return _repository.getMonthlySummary(month);
  }

  Future<List<TransactionRecord>> getRecentTransactions({
    int limit = 5,
    ExpenseFilter filter = const ExpenseFilter(),
  }) {
    return _repository.getTransactions(filter: filter, limit: limit);
  }

  Future<List<TransactionRecord>> searchTransactions(ExpenseFilter filter) {
    return _repository.getTransactions(filter: filter);
  }
}
