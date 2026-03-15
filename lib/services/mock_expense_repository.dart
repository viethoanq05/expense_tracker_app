import 'package:expense_tracker_app/models/category_record.dart';
import 'package:expense_tracker_app/models/dashboard_summary.dart';
import 'package:expense_tracker_app/models/expense_filter.dart';
import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/services/expense_repository.dart';

class MockExpenseRepository implements ExpenseRepository {
  MockExpenseRepository({
    List<TransactionRecord>? seedTransactions,
    List<CategoryRecord>? seedCategories,
  }) : _transactions = [...(seedTransactions ?? _defaultTransactions)],
       _categories = [...(seedCategories ?? _defaultCategories)];

  final List<TransactionRecord> _transactions;
  final List<CategoryRecord> _categories;

  @override
  Future<void> addTransaction(TransactionRecord transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((tx) => tx.id == transactionId);
  }

  @override
  Future<List<CategoryRecord>> getCategories() async {
    return [..._categories];
  }

  @override
  Future<DashboardSummary> getMonthlySummary(DateTime month) async {
    final monthly = _transactions.where(
      (tx) => tx.date.year == month.year && tx.date.month == month.month,
    );

    double income = 0;
    double expense = 0;
    int count = 0;

    for (final tx in monthly) {
      count++;
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return DashboardSummary(
      monthlyIncome: income,
      monthlyExpense: expense,
      monthlyBalance: income - expense,
      transactionCount: count,
    );
  }

  @override
  Future<List<TransactionRecord>> getTransactions({
    ExpenseFilter filter = const ExpenseFilter(),
    int? limit,
  }) async {
    final now = DateTime.now();
    final filtered =
        _transactions
            .where((tx) => filter.matches(tx, now))
            .toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));

    if (limit == null || filtered.length <= limit) {
      return filtered;
    }

    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<void> updateTransaction(TransactionRecord transaction) async {
    final index = _transactions.indexWhere((tx) => tx.id == transaction.id);
    if (index == -1) {
      return;
    }

    _transactions[index] = transaction;
  }

  static const List<CategoryRecord> _defaultCategories = [
    CategoryRecord(
      id: 'cat_salary',
      name: 'Salary',
      type: TransactionType.income,
      icon: 'payments',
      colorHex: '#1D9A6C',
    ),
    CategoryRecord(
      id: 'cat_freelance',
      name: 'Freelance',
      type: TransactionType.income,
      icon: 'laptop_mac',
      colorHex: '#00796B',
    ),
    CategoryRecord(
      id: 'cat_food',
      name: 'Food',
      type: TransactionType.expense,
      icon: 'restaurant',
      colorHex: '#C65A1E',
    ),
    CategoryRecord(
      id: 'cat_transport',
      name: 'Transport',
      type: TransactionType.expense,
      icon: 'directions_car',
      colorHex: '#2E5AAC',
    ),
    CategoryRecord(
      id: 'cat_housing',
      name: 'Housing',
      type: TransactionType.expense,
      icon: 'home',
      colorHex: '#A24566',
    ),
    CategoryRecord(
      id: 'cat_shopping',
      name: 'Shopping',
      type: TransactionType.expense,
      icon: 'shopping_bag',
      colorHex: '#7158A8',
    ),
  ];

  static final List<TransactionRecord> _defaultTransactions = [
    TransactionRecord(
      id: 'tx_001',
      title: 'Lương tháng 3',
      amount: 18500000,
      date: DateTime(2026, 3, 1),
      category: 'Salary',
      type: TransactionType.income,
      note: 'Công ty ABC',
    ),
    TransactionRecord(
      id: 'tx_002',
      title: 'Ăn trưa văn phòng',
      amount: 85000,
      date: DateTime(2026, 3, 12),
      category: 'Food',
      type: TransactionType.expense,
    ),
    TransactionRecord(
      id: 'tx_003',
      title: 'Cafe họp nhóm',
      amount: 58000,
      date: DateTime(2026, 3, 11),
      category: 'Food',
      type: TransactionType.expense,
    ),
    TransactionRecord(
      id: 'tx_004',
      title: 'Di chuyển Grab',
      amount: 124000,
      date: DateTime(2026, 3, 10),
      category: 'Transport',
      type: TransactionType.expense,
    ),
    TransactionRecord(
      id: 'tx_005',
      title: 'Mua đồ gia dụng',
      amount: 332000,
      date: DateTime(2026, 3, 9),
      category: 'Shopping',
      type: TransactionType.expense,
    ),
    TransactionRecord(
      id: 'tx_006',
      title: 'Freelance sprint UI',
      amount: 2100000,
      date: DateTime(2026, 3, 7),
      category: 'Freelance',
      type: TransactionType.income,
    ),
    TransactionRecord(
      id: 'tx_007',
      title: 'Tiền nhà',
      amount: 3500000,
      date: DateTime(2026, 3, 5),
      category: 'Housing',
      type: TransactionType.expense,
    ),
    TransactionRecord(
      id: 'tx_008',
      title: 'Netflix',
      amount: 260000,
      date: DateTime(2026, 3, 4),
      category: 'Subscription',
      type: TransactionType.expense,
    ),
    TransactionRecord(
      id: 'tx_009',
      title: 'Hoan tien dat xe',
      amount: 54000,
      date: DateTime(2026, 2, 28),
      category: 'Refund',
      type: TransactionType.income,
    ),
    TransactionRecord(
      id: 'tx_010',
      title: 'Siêu thị cuối tuần',
      amount: 675000,
      date: DateTime(2026, 2, 26),
      category: 'Groceries',
      type: TransactionType.expense,
    ),
    TransactionRecord(
      id: 'tx_011',
      title: 'Học phí online',
      amount: 499000,
      date: DateTime(2026, 2, 21),
      category: 'Education',
      type: TransactionType.expense,
    ),
  ];
}
